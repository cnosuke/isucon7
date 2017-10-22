# https://github.com/puma/puma/blob/master/examples/config.rb

threads_min_count = ENV.fetch("SINATRA_MIN_THREADS") { 4 }
threads_max_count = ENV.fetch("SINATRA_MAX_THREADS") { 16 }
threads threads_min_count, threads_max_count

environment ENV.fetch("SINATRA_ENV") { 'production' }

plugin :tmp_restart

bind ENV.fetch("SINATRA_BIND") { '/tmp/puma.sock' }
