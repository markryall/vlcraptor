# frozen_string_literal: true

require "yaml"
require "fileutils"

module Vlcraptor
  class Settings
    attr_reader :path, :preferences

    def initialize(path)
      @path = path.gsub("~", File.expand_path("~"))
      FileUtils.mkdir_p File.dirname(@path)
      @preferences = File.exist?(@path) ? YAML.load_file(@path) : {}
    end

    def [](key)
      preferences[key]
    end

    def []=(key, value)
      preferences[key] = value
      persist
    end

    def persist
      File.open(path, "w") { |f| f.puts preferences.to_yaml }
    end
  end
end
