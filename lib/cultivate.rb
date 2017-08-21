
warn "This was tested on Ruby 2.4.1, but you're using #{RUBY_VERSION}" if
  RUBY_VERSION != '2.4.1'

module Cultivate
  def self.traverse paths, &block
    paths.each do |p|
      if File.file?(p)
        yield(p)
      elsif File.directory?(p)
        Dir["#{p}/**/*"].each(&block)
      end
    end
  end

  def self.setup path
    require_relative 'cultivate/database'
    connect(path)
    require_relative 'cultivate/model'
  end

  def self.connect path
    if File.exist?(path)
      connect_db(path)
    else
      require 'fileutils'
      FileUtils.mkdir_p(File.dirname(path))

      connect_db(path)

      Database.create_table
    end
  end

  def self.connect_db path
    Database.db = Sequel.connect("sqlite://#{path}")
  end
end
