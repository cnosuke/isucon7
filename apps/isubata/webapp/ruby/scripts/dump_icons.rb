require 'mysql2'
require File.join(__dir__, "../image_handler")

require 'pry'

class App
  def self.db
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

  def self.dump!
    statement = self.db.prepare('SELECT * FROM image')

    statement.execute.each do |r|
      ImageHandler.save_icon_image!(r['name'], r['data'])
    end

    statement.close
  end
end

App.dump!
