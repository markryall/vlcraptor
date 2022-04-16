# frozen_string_literal: true

require "yaml"
require_relative "ffmpeg"

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

    def self.add(path)
      unless %w[.mp3 .m4a].include?(File.extname(path))
        puts "skipping #{path}"
        return
      end

      puts "adding #{path}"
      tags = Vlcraptor::Ffmpeg.new(path)
      meta = {
        title: tags.title,
        artist: tags.artist,
        album: tags.album,
        length: tags.time,
        path: path,
      }
      `mkdir -p /tmp/queue`
      File.open("/tmp/queue/#{(Time.now.to_f * 1000).to_i}.yml", "w") { |f| f.puts meta.to_yaml }
    end
  end
end
