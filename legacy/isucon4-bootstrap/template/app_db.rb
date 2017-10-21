# -*- coding: undecided -*-
# puma.io でmysqlの接続数を制御するメモ。
# ファイルディスクリプタが詰まる可能性もある点に注意

def dbconfig
  $dbconfig ||=  JSON.parse(IO.read(File.dirname(__FILE__) + "/../config/#{ ENV['ISUCON_ENV'] || 'local' }.json"))['database']
end

def connection_for_puma
  $dbidx += 1
  $dbidx = 0 if $dbidx > 4000
  $dbs[$dbidx]
  if $dbs[$dbidx]
    $dbs[$dbidx]
  else
    connection_for_puma
  end
end

def connection_for_unicorn
  config = dbconfig
  return $mysql if $mysql
    $mysql = Mysql2::Client.new(
    :host => config['host'],
    :port => config['port'],
    :username => config['username'],
    :password => config['password'],
    :database => config['dbname'],
    :reconnect => true,
  )
 nd

def connection
  connection_for_puma
end
