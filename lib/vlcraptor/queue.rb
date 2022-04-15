# frozen_string_literal: true

require "yaml"

module Vlcraptor
  class Queue
    def initialize
      @current_path = nil
    end

    def next
      `rm -f #{@current_path}` if @current_path
      @current_path = Dir["/tmp/queue/*.yml"].min
      YAML.load_file(@current_path) if @current_path
    end

    def self.each
      Dir["/tmp/queue/*.yml"].sort.each do |path|
        yield YAML.load_file path
      end
    end
  end
end
