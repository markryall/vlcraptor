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
      return unless @current_path

      result = YAML.load_file(@current_path)
      File.exist?(result[:path]) ? result : self.next
    end

    def self.clear
      `rm -rf /tmp/queue`
    end

    def self.length
      Dir["/tmp/queue/*.yml"].length
    end

    def self.each
      Dir["/tmp/queue/*.yml"].sort.each do |path|
        yield YAML.load_file path
      end
    end

    def self.remove(index)
      path = Dir["/tmp/queue/*.yml"].sort[index.to_i]
      if path
        `rm #{path}`
        yield
      else
        puts "Could not find track at position #{index}"
      end
    end

    def self.swap(a, b)
      all = Dir["/tmp/queue/*.yml"].sort
      path_a = all[a.to_i]
      path_b = all[b.to_i]

      if path_a && path_b
        `mv #{path_a} #{path_a}.tmp`
        `mv #{path_b} #{path_a}`
        `mv #{path_a}.tmp #{path_b}`
        yield
      else
        puts "Could not find tracks at positions #{a} and #{b}"
      end
    end

    def self.add(path)
      unless %w[.mp3 .m4a].include?(File.extname(path))
        puts "skipping #{path}"
        return
      end

      puts "adding #{path}"
      tags = Vlcraptor::Ffmpeg.new(path)
      enqueue(
        title: tags.title,
        artist: tags.artist,
        album: tags.album,
        length: tags.time,
        path: File.expand_path(path)
      )
    end

    def self.enqueue(track)
      `mkdir -p /tmp/queue`
      File.open("/tmp/queue/#{(Time.now.to_f * 1000).to_i}.yml", "w") do |file|
        file.puts track.to_yaml
      end
    end
  end
end
