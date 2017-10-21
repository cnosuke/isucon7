require 'digest/sha1'
require 'json'
require 'net/http'
require 'uri'

require 'erubis'
require 'mysql2'
require 'mysql2-cs-bind'
require 'rack/utils'
require 'sinatra/base'
require 'tilt/erubis'
require 'redis'

# require 'newrelic_rpm'

module Isuda
  class Web < ::Sinatra::Base
    enable :protection
    enable :sessions

    set :erb, escape_html: true
    set :public_folder, File.expand_path('../../../../public', __FILE__)
    set :db_user, ENV['ISUDA_DB_USER'] || 'root'
    set :db_password, ENV['ISUDA_DB_PASSWORD'] || ''
    set :dsn, ENV['ISUDA_DSN'] || 'dbi:mysql:db=isuda'
    set :session_secret, 'tonymoris'
    set :isupam_origin, ENV['ISUPAM_ORIGIN'] || 'http://localhost:5050'

    configure :development do
      require 'pry'
      require 'rack-lineprof'
      require 'sinatra/reloader'

      register Sinatra::Reloader
      use Rack::Lineprof
    end

    set(:set_name) do |value|
      condition {
        user_id = session[:user_id]
        if user_id
          user = db.xquery(%| select name from user where id = ? |.freeze, user_id).first
          @user_id = user_id
          @user_name = user[:name]
          halt(403) unless @user_name
        end
      }
    end

    set(:authenticate) do |value|
      condition {
        halt(403) unless @user_id
      }
    end

    helpers do
      def db
        Thread.current[:db] ||=
          begin
            _, _, attrs_part = settings.dsn.split(':', 3)
            attrs = Hash[attrs_part.split(';').map {|part| part.split('=', 2) }]
            mysql = Mysql2::Client.new(
              username: settings.db_user,
              password: settings.db_password,
              database: attrs['db'],
              encoding: 'utf8mb4',
              init_command: %|SET SESSION sql_mode='TRADITIONAL,NO_AUTO_VALUE_ON_ZERO,ONLY_FULL_GROUP_BY'|,
            )
            mysql.query_options.update(symbolize_keys: true)
            mysql
          end
      end

      def redis
        Thread.current[:redis] ||= ::Redis.new(
          host: '127.0.0.1', port: 6379, driver: 'hiredis'
        )
      end

      def register(name, pw)
        db.xquery(%|
          INSERT INTO user (name, salt, password, created_at)
          VALUES (?, ?, ?, NOW())
        |.freeze, name, '', '')
        db.last_id
      end

      def is_spam_content(content)
        isupam_uri = URI(settings.isupam_origin)
        res = Net::HTTP.post_form(isupam_uri, 'content'.freeze => content)
        validation = JSON.parse(res.body)
        validation['valid'.freeze]
        ! validation['valid'.freeze]
      end

      # バグるかも: escaped_content, anchor からescape_htmlをやめたよ 5dcb180
      def htmlify(content, pattern = nil)
        content.gsub!(pattern || keyword_pattern) {|m|
          keyword_url = url("/keyword/#{Rack::Utils.escape_path(m)}")
          '<a href="%s">%s</a>'.freeze % [keyword_url, m]
        }
        content.gsub!(/\n/, "<br />\n".freeze)
        content
      end

      def cached_html(entry, pattern = nil)
        html = redis.get("cached_html:#{entry[:keyword]}")
        return html if html

        htmlify(entry[:description], pattern).tap do |html|
          redis.set("cached_html:#{entry[:keyword]}", html)
        end
      end

      def flush_cached_html
        keys = redis.keys('cached_html:*'.freeze)
        return if keys.empty?
        redis.del(*keys)
      end

      def cached_total_entries
        redis.get('total_entries'.freeze).to_i
      end

      def update_total_entries
        db.xquery(%| SELECT count(1) AS total_entries FROM entry |.freeze).first[:total_entries].to_i.tap do |total_entries|
          redis.set('total_entries'.freeze, total_entries)
        end
      end

      def uri_escape(str)
        Rack::Utils.escape_path(str)
      end

      def load_stars(keyword)
        # db.xquery(%| select * from star where keyword = ? |, keyword).to_a
        return [] unless keyword
        redis.lrange(keyword, 0, 100).reverse.map do |user_name|
          { keyword: keyword, user_name: user_name }
        end
      end

      def redirect_found(path)
        redirect(path, 302)
      end

      def keyword_pattern
        dump = redis.get('keyword_pattern'.freeze)
        return Marshal.load(dump) if dump

        Regexp.union(
          db.xquery(%| select keyword from entry order by keyword_length desc |.freeze).map { |k| k[:keyword] }
        ).tap do |pattern|
          redis.set('keyword_pattern'.freeze, Marshal.dump(pattern))
        end
      end

      def purge_keyword_pattern
        redis.del('keyword_pattern'.freeze)
      end
    end

    get '/initialize'.freeze do
      redis.flushall
      db.xquery(%| DELETE FROM entry WHERE id > 7101 |)
      db.xquery(%| SELECT id, keyword FROM entry |).each do |entry|
        db.xquery(%| UPDATE entry SET keyword_length = ? WHERE id = ? |, entry[:keyword].length, entry[:id])
      end
      db.xquery(%| TRUNCATE star |)
      update_total_entries

      5.times do |i|
        system("curl http://127.0.0.1/?page=#{i}")
      end

      content_type :json
      JSON.generate(result: 'ok'.freeze)
    end

    ### isutar
    get '/stars'.freeze do
      return '{"stars":[]}'.freeze unless params[:keyword]
      keyword = params[:keyword]
      stars = redis.lrange(keyword, 0, 100).reverse.map do |user_name|
        { keyword: keyword, user_name: user_name }
      end

      content_type :json
      JSON.generate(stars: stars)
    end

    post '/stars'.freeze do
      keyword = params[:keyword] or halt(400)
      db.xquery(%| select * from entry where keyword = ? |.freeze, keyword).first or halt(404)

      redis.lpush(keyword, params[:user])

      content_type :json
      JSON.generate(result: 'ok'.freeze)
    end

    ### isuda
    get '/'.freeze, set_name: true do
      per_page = 10
      page = (params[:page] || 1).to_i

      entries = db.xquery(%|
        SELECT * FROM entry
        ORDER BY updated_at DESC
        LIMIT #{per_page}
        OFFSET #{per_page * (page - 1)}
      |)
      pattern = keyword_pattern
      entries.each do |entry|
        entry[:html] = cached_html(entry, pattern)
        entry[:stars] = load_stars(entry[:keyword])
      end

      total_entries = cached_total_entries

      last_page = (total_entries.to_f / per_page.to_f).ceil
      from = [1, page - 5].max
      to = [last_page, page + 5].min
      pages = [*from..to]

      locals = {
        entries: entries,
        page: page,
        pages: pages,
        last_page: last_page,
      }
      erb :index, locals: locals
    end

    get '/robots.txt'.freeze do
      halt(404)
    end

    get '/register'.freeze, set_name: true do
      erb :register
    end

    post '/register'.freeze do
      name = params[:name] || ''.freeze
      pw   = params[:password] || ''.freeze
      halt(400) if (name == ''.freeze) || (pw == ''.freeze)

      user_id = register(name, pw)
      session[:user_id] = user_id

      redirect_found '/'.freeze
    end

    get '/login'.freeze, set_name: true do
      locals = {
        action: 'login'.freeze,
      }
      erb :authenticate, locals: locals
    end

    post '/login'.freeze do
      name = params[:name]
      user = db.xquery(%| select * from user where name = ? |.freeze, name).first
      halt(403) unless user
      halt(403) unless params[:name] == params[:password]

      session[:user_id] = user[:id]

      redirect_found '/'.freeze
    end

    get '/logout'.freeze do
      session[:user_id] = nil
      redirect_found '/'.freeze
    end

    post '/keyword'.freeze, set_name: true, authenticate: true do
      keyword = params[:keyword] || ''.freeze
      halt(400) if keyword == ''.freeze
      description = params[:description]
      halt(400) if is_spam_content("#{description}#{keyword}")

      old_total_entries = cached_total_entries

      bound = [@user_id, keyword, description, keyword.length] * 2
      db.xquery(%|
        INSERT INTO entry (author_id, keyword, description, created_at, updated_at, keyword_length)
        VALUES (?, ?, ?, NOW(), NOW(), ?)
        ON DUPLICATE KEY UPDATE
        author_id = ?, keyword = ?, description = ?, updated_at = NOW(), keyword_length = ?
      |.freeze, *bound)

      new_total_entries = update_total_entries
      if new_total_entries > old_total_entries
        purge_keyword_pattern
        flush_cached_html
      end
      redis.del("cached_html:#{keyword}")

      redirect_found '/'.freeze
    end

    get '/keyword/:keyword'.freeze, set_name: true do
      keyword = params[:keyword] or halt(400)

      entry = db.xquery(%| select * from entry where keyword = ? |.freeze, keyword).first or halt(404)
      entry[:stars] = load_stars(entry[:keyword])
      entry[:html] = cached_html(entry)

      locals = {
        entry: entry,
      }
      erb :keyword, locals: locals
    end

    post '/keyword/:keyword'.freeze, set_name: true, authenticate: true do
      keyword = params[:keyword] or halt(400)
      params[:delete] or halt(400)

      unless db.xquery(%| SELECT * FROM entry WHERE keyword = ? |.freeze, keyword).first
        halt(404)
      end

      db.xquery(%| DELETE FROM entry WHERE keyword = ? |.freeze, keyword)
      purge_keyword_pattern
      flush_cached_html

      redirect_found '/'.freeze
    end
  end
end
