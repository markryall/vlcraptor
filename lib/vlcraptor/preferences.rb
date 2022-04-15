# frozen_string_literal: true

require "yaml"
require "fileutils"

module Vlcraptor
  class Preferences
    def initialize
      @path = "#{File.expand_path("~")}/.player"
      persist({ autoplay: true, crossfade: true }) unless File.exist?(@path)
    end

    def continue?
      self[:autoplay]
    end

    def crossfade?
      self[:autoplay] && self[:crossfade]
    end

    def [](key)
      load_preferences[key]
    end

    def []=(key, value)
      preferences = load_preferences
      preferences[key] = value
      persist(preferences)
    end

    def persist(preferences)
      File.open(@path, "w") { |f| f.puts preferences.to_yaml }
    end

    private

    def load_preferences
      YAML.load_file(@path)
    end
  end
end
