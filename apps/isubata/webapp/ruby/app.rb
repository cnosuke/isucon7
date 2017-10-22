require 'digest/sha1'
require 'mysql2'
require 'sinatra/base'
#require 'newrelic_rpm'
#require 'rack-lineprof'

require './image_handler'

class App < Sinatra::Base
  # curl 'http://localhost:9292/fetch?lineprof=app.rb' ...
  #use Rack::Lineprof

  configure do
    set :session_secret, 'tonymoris'
    set :public_folder, File.expand_path('../../public', __FILE__)
    set :avatar_max_size, 1 * 1024 * 1024

    enable :sessions
  end

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  helpers do
    def user
      return @_user unless @_user.nil?

      user_id = session[:user_id]
      return nil if user_id.nil?

      @_user = db_get_user(user_id)
      if @_user.nil?
        params[:user_id] = nil
        return nil
      end

      @_user
    end
  end

  get '/initialize' do
    db.query("DELETE FROM user WHERE id > 1000")
    db.query("DELETE FROM image WHERE id > 1001")
    db.query("DELETE FROM channel WHERE id > 10")
    db.query("DELETE FROM message WHERE id > 10000")
    db.query("DELETE FROM haveread")
    204
  end

  get '/' do
    if session.has_key?(:user_id)
      return redirect '/channel/1', 303
    end
    erb :index
  end

  get '/channel/:channel_id' do
    if user.nil?
      return redirect '/login', 303
    end

    @channel_id = params[:channel_id].to_i
    @channels, @description = get_channel_list_info(@channel_id)
    erb :channel
  end

  get '/register' do
    erb :register
  end

  post '/register' do
    name = params[:name]
    pw = params[:password]
    if name.nil? || name.empty? || pw.nil? || pw.empty?
      return 400
    end
    begin
      user_id = register(name, pw)
    rescue Mysql2::Error => e
      return 409 if e.error_number == 1062
      raise e
    end
    session[:user_id] = user_id
    redirect '/', 303
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    name = params[:name]
    statement = db.prepare('SELECT id, password, salt FROM user WHERE name = ? LIMIT 1')
    row = statement.execute(name).first
    if row.nil? || row['password'] != Digest::SHA1.hexdigest(row['salt'] + params[:password])
      return 403
    end
    statement.close
    session[:user_id] = row['id']
    redirect '/', 303
  end

  get '/logout' do
    session[:user_id] = nil
    redirect '/', 303
  end

  post '/message' do
    user_id = session[:user_id]
    message = params[:message]
    channel_id = params[:channel_id]
    if user_id.nil? || message.nil? || channel_id.nil? || user.nil?
      return 403
    end
    db_add_message(channel_id.to_i, user_id, message)
    204
  end

  get '/message' do
    user_id = session[:user_id]
    if user_id.nil?
      return 403
    end

    channel_id = params[:channel_id].to_i
    last_message_id = params[:last_message_id].to_i

    # Load messages (main)
    statement = db.prepare('SELECT id, user_id, content, created_at FROM message WHERE id > ? AND channel_id = ? ORDER BY id DESC LIMIT 100')
    rows = statement.execute(last_message_id, channel_id).to_a
    statement.close

    # Load nested users (sub, to resolve N+1)
    if rows.length > 0
      statement = db.prepare("SELECT id, name, display_name, avatar_icon FROM user WHERE id IN (#{rows.length.times.map { '?' }.join(',')})")
      user_rows = statement.execute(*rows.map { |r| r['user_id'] }).to_a
      statement.close
    else
      user_rows = []
    end

    response = []
    rows.each do |row|
      r = {}
      r['id'] = row['id']
      r['user'] = user_rows.find { |u| u['id'] == row['user_id'] }
      r['date'] = row['created_at'].strftime("%Y/%m/%d %H:%M:%S")
      r['content'] = row['content']
      response << r
    end
    response.reverse!

    max_message_id = rows.empty? ? 0 : rows.map { |row| row['id'] }.max
    statement = db.prepare([
      'INSERT INTO haveread (user_id, channel_id, message_id, updated_at, created_at) ',
      'VALUES (?, ?, ?, NOW(), NOW()) ',
      'ON DUPLICATE KEY UPDATE message_id = ?, updated_at = NOW()',
    ].join)
    statement.execute(user_id, channel_id, max_message_id, max_message_id)
    statement.close

    content_type :json
    response.to_json
  end

  get '/fetch' do
    user_id = session[:user_id]
    if user_id.nil?
      return 403
    end

    rows = db.query('SELECT id FROM channel').to_a
    channel_ids = rows.map { |row| row['id'] }

    res = []

    # resolve N+1
    if channel_ids.length > 0
      statement = db.prepare("SELECT message_id, channel_id FROM haveread WHERE user_id = ? AND channel_id IN (#{channel_ids.map { '?' }.join(',')})")
      havereads = statement.execute(user_id, *channel_ids).to_a
      statement.close
    else
      havereads = []
    end

    channel_ids.each do |channel_id|
      r = {}
      r['channel_id'] = channel_id
      row = havereads.find { |haveread| haveread['channel_id'] == channel_id }
      r['unread'] = if row.nil?
        statement = db.prepare('SELECT COUNT(*) as cnt FROM message WHERE channel_id = ?')
        statement.execute(channel_id).first['cnt']
      else
        statement = db.prepare('SELECT COUNT(*) as cnt FROM message WHERE channel_id = ? AND ? < id')
        statement.execute(channel_id, row['message_id']).first['cnt']
      end
      statement.close
      res << r
    end

    content_type :json
    res.to_json
  end

  get '/history/:channel_id' do
    if user.nil?
      return redirect '/login', 303
    end

    @channel_id = params[:channel_id].to_i

    @page = params[:page]
    if @page.nil?
      @page = '1'
    end
    if @page !~ /\A\d+\Z/ || @page == '0'
      return 400
    end
    @page = @page.to_i

    n = 20
    statement = db.prepare('SELECT * FROM message WHERE channel_id = ? ORDER BY id DESC LIMIT ? OFFSET ?')
    rows = statement.execute(@channel_id, n, (@page - 1) * n).to_a
    statement.close
    @messages = []

    user_ids = rows.map { |r| r['user_id'] }.uniq

    if user_ids.length > 0
      user_statement = db.prepare("SELECT id, name, display_name, avatar_icon FROM user WHERE id IN (#{user_ids.length.times.map{ '?' }.join(',')})")
      user_rows = user_statement.execute(*user_ids).to_a
      user_statement.close
    else
      user_rows = []
    end

    rows.each do |row|
      r = {}
      r['id'] = row['id']
      r['user'] = user_rows.find { |r| r['id'] == row['user_id']}
      r['date'] = row['created_at'].strftime("%Y/%m/%d %H:%M:%S")
      r['content'] = row['content']
      @messages << r
    end
    @messages.reverse!

    statement = db.prepare('SELECT COUNT(*) as cnt FROM message WHERE channel_id = ?')
    cnt = statement.execute(@channel_id).first['cnt'].to_f
    statement.close
    @max_page = cnt == 0 ? 1 :(cnt / n).ceil

    return 400 if @page > @max_page

    @channels, @description = get_channel_list_info(@channel_id)
    erb :history
  end

  get '/profile/:user_name' do
    if user.nil?
      return redirect '/login', 303
    end

    @channels, = get_channel_list_info

    user_name = params[:user_name]
    unless @self_profile = (user['name'] == user_name)
      statement = db.prepare('SELECT name, display_name, avatar_icon FROM user WHERE name = ? LIMIT 1')
      @user = statement.execute(user_name).first
      statement.close

      if @user.nil?
        return 404
      end
    end

    erb :profile
  end

  get '/add_channel' do
    if user.nil?
      return redirect '/login', 303
    end

    @channels, = get_channel_list_info
    erb :add_channel
  end

  post '/add_channel' do
    if user.nil?
      return redirect '/login', 303
    end

    name = params[:name]
    description = params[:description]
    if name.nil? || description.nil?
      return 400
    end
    statement = db.prepare('INSERT INTO channel (name, description, updated_at, created_at) VALUES (?, ?, NOW(), NOW())')
    statement.execute(name, description)
    channel_id = db.last_id
    statement.close
    redirect "/channel/#{channel_id}", 303
  end

  post '/profile' do
    if user.nil?
      return redirect '/login', 303
    end

    if user.nil?
      return 403
    end

    display_name = params[:display_name]
    avatar_name = nil
    avatar_data = nil

    file = params[:avatar_icon]
    unless file.nil?
      filename = file[:filename]
      if !filename.nil? && !filename.empty?
        ext = filename.include?('.') ? File.extname(filename) : ''
        unless ['.jpg', '.jpeg', '.png', '.gif'].include?(ext)
          return 400
        end

        if settings.avatar_max_size < file[:tempfile].size
          return 400
        end

        data = file[:tempfile].read
        digest = Digest::SHA1.hexdigest(data)

        avatar_name = digest + ext
        avatar_data = data
      end
    end

    if !avatar_name.nil? && !avatar_data.nil?
      ImageHandler.save_icon_image!(avatar_name, avatar_data)

      statement = db.prepare('UPDATE user SET avatar_icon = ? WHERE id = ?')
      statement.execute(avatar_name, user['id'])
      statement.close
    end

    if !display_name.nil? || !display_name.empty?
      statement = db.prepare('UPDATE user SET display_name = ? WHERE id = ?')
      statement.execute(display_name, user['id'])
      statement.close
    end

    redirect '/', 303
  end

  # 画像ファイルはnginxが返すようにしたのでこのエンドポイントは使ってない！！！
  # ただしローカルでは動かしたいので残してある。
  get '/icons/:file_name' do
    file_name = params[:file_name]

    if ImageHandler.exist?(file_name)
      ext = file_name.include?('.') ? File.extname(file_name) : ''
      mime = ext2mime(ext)
      content_type mime
      return ImageHandler.read_data(file_name)
    else
      return 404
    end
  end

  private

  def db
    return @db_client if defined?(@db_client)

    @db_client = Mysql2::Client.new(
      host: ENV.fetch('ISUBATA_DB_HOST') { 'localhost' },
      port: ENV.fetch('ISUBATA_DB_PORT') { '3306' },
      username: ENV.fetch('ISUBATA_DB_USER') { 'root' },
      password: ENV.fetch('ISUBATA_DB_PASSWORD') { '' },
      database: 'isubata',
      encoding: 'utf8mb4'
    )
    @db_client.query('SET SESSION sql_mode=\'TRADITIONAL,NO_AUTO_VALUE_ON_ZERO,ONLY_FULL_GROUP_BY\'')
    @db_client
  end

  def db_get_user(user_id)
    statement = db.prepare('SELECT id, name, display_name, avatar_icon FROM user WHERE id = ?')
    user = statement.execute(user_id).first
    statement.close
    user
  end

  def db_add_message(channel_id, user_id, content)
    statement = db.prepare('INSERT INTO message (channel_id, user_id, content, created_at) VALUES (?, ?, ?, NOW())')
    messages = statement.execute(channel_id, user_id, content)
    statement.close
    messages
  end

  def register(user, password)
    salt = 'salt'.freeze
    pass_digest = Digest::SHA1.hexdigest(salt + password).freeze
    statement = db.prepare('INSERT INTO user (name, salt, password, display_name, avatar_icon, created_at) VALUES (?, ?, ?, ?, ?, NOW())')
    statement.execute(user, salt, pass_digest, user, 'default.png')
    row = db.query('SELECT LAST_INSERT_ID() AS last_insert_id').first
    statement.close
    row['last_insert_id']
  end

  def get_channel_list_info(focus_channel_id = nil)
    channels = db.query('SELECT * FROM channel ORDER BY id').to_a
    description = focus_channel_id.nil? ?
                      '' :
                      channels.find { |chan| chan['id'] == focus_channel_id }['description']
    [channels, description]
  end

  def ext2mime(ext)
    if ['.jpg', '.jpeg'].include?(ext)
      return 'image/jpeg'
    end
    if ext == '.png'
      return 'image/png'
    end
    if ext == '.gif'
      return 'image/gif'
    end
    ''
  end
end
