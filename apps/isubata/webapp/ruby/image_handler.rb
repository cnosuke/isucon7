class ImageHandler

  DIR = "#{__dir__}/icons"

  class << self
    def save_icon_image!(name, data)
      open(
        File.join(DIR, name).to_s, 'w'
      ) { |io| io.print data }
    end

    def exist?(name)
      File.exist?(
        File.join(DIR, name).to_s
      )
    end
  end
end
