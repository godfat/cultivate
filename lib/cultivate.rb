
ruby_version = '2.5.1'

if RUBY_VERSION != ruby_version
  warn "This was tested on Ruby #{ruby_version}," \
       " but you're using #{RUBY_VERSION}"
end

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
    Database.db =
      case path
      when ':memory:'
        Sequel.sqlite
      else
        Sequel.connect("sqlite://#{path}")
      end
  end
end
