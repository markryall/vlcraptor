# frozen_string_literal: true

require "vlc-client"

module Vlcraptor
  class Player
    def initialize
      vlc_host = ENV.fetch("VLC_HOST", "localhost")
      vlc_port_one = ENV.fetch("VLC_PORT", 4212)
      vlc_port_two = ENV.fetch("VLC_PORT", 4213)

      @pid_one = spawn(
        "/Applications/VLC.app/Contents/MacOS/VLC --intf rc --rc-host localhost:#{vlc_port_one}",
        %i[out err] => "/dev/null"
      )

      @pid_two = spawn(
        "/Applications/VLC.app/Contents/MacOS/VLC --intf rc --rc-host localhost:#{vlc_port_two}",
        %i[out err] => "/dev/null"
      )

      # wait a bit for the VLC processes to be started
      sleep 0.5

      @vlc = VLC::Client.new(vlc_host, vlc_port_one)
      @vlc.connect

      @vlc_other = VLC::Client.new(vlc_host, vlc_port_two)
      @vlc_other.connect
    end

    def playing?
      @vlc.playing?
    end

    def time
      @vlc.time
    end

    def remaining
      @vlc.length - @vlc.time
    end

    def fadeout
      (0..10).each do |index|
        diff = (256 * index) / 10
        @vlc.volume = 256 - diff
        sleep 0.5
      end

      @vlc.stop
    end

    def crossfade(path)
      @vlc_other.volume = 0
      @vlc_other.play path

      (0..10).each do |index|
        diff = (256 * index) / 10
        @vlc.volume = 256 - diff
        @vlc_other.volume = diff
        sleep 0.5
      end

      @vlc.stop
      @vlc, @vlc_other = @vlc_other, @vlc
    end

    def play(path = nil)
      @vlc.play(path)
    end

    def pause
      @vlc.pause
    end

    def stop
      @vlc.stop
    end

    def cleanup
      `kill -9 #{@pid_one}` if @pid_one
      `kill -9 #{@pid_two}` if @pid_two
    end
  end
end
