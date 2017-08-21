
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

  def self.connect path
    require_relative 'cultivate/database'

    existing_db = File.exist?(path)
    Database.db = Sequel.connect("sqlite://#{path}")
    Database.create_table unless existing_db

    require_relative 'cultivate/model'
  end
end
