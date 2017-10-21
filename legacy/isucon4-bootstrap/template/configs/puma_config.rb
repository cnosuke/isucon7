# -*- coding: utf-8 -*-

# ~/isucon/env.sh bundle exec puma -C puma_config.rb

require 'json'

root = "/home/isu-user/isucon/webapp/ruby" 

threads 8,32
workers 4
preload_app!

pidfile "#{root}/tmp/puma.pid"
bind 'unix:///tmp/sinatra.sock'

stdout_redirect "#{root}/log/puma.log", "#{root}/log/puma_err.log"

on_worker_boot do
# connection poolとかするならここに書くべき？
# だが、同時接続数大きくなるからconnection poolしないほうがよさそう
# 設定情報だけキャッシュして毎回接続に行くようにして、nginxの最大接続が4*1024ならmy.cnfの最大接続も4*1024にすればtoo many connectionsは出ない


# 大量のconnection poolを使って使い回すときはここの段階でつくる
# config = JSON.parse(IO.read(File.dirname(__FILE__) + "/../config/#{ ENV['ISUCON_ENV'] || 'local' }.json"))['database']

# $dbs = 1000.times.map do
#      Mysql2::Client.new(
#        :host => config['host'],
#        :port => config['port'],
#        :username => config['username'],
#        :password => config['password'],
#        :database => config['dbname'],
#        :reconnect => true,
#      )
# end

# $dbidx = 0

end
