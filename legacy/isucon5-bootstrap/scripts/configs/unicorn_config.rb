# -*- coding: utf-8 -*-
# http://unicorn.bogomips.org/Unicorn/Configurator.html

# You should `mkdir tmp` and `mkdir log`

worker_processes 12
preload_app true

listen "127.0.0.1:3000"
#listen "/tmp/sinatra.sock" # 絶対パスでなければならない点に注意！
timeout 600

pid '/tmp/unicorn.pid'

#logger Logger.new('log/unicorn.log')
#set[:logger].level = Logger::ERROR

stderr_path '/tmp/unicorn.stdout.log'
stdout_path '/tmp/unicorn.stderr.log'

GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

after_fork do |server, worker|
#  GC.disable if RAILS_ENV == 'production'
end
