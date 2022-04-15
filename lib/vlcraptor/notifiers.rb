# frozen_string_literal: true

require "rainbow"
require_relative "console"
require_relative "scrobbler"

module Vlcraptor
  class Notifiers
    def initialize(preferences)
      @preferences = preferences
      @console = Vlcraptor::Console.new
    end

    def track_progress(track, remaining)
      return unless track

      rem = if remaining > 60
              "#{remaining / 60} minutes and #{remaining % 60} seconds remaining"
            else
              "#{remaining} seconds remaining"
            end
      @console.change(
        [
          "        ",
          display_time(Time.now + remaining),
          remaining < 20 ? Rainbow(rem).tomato : rem,
        ].join(" ")
      )
    end

    def track_started(track)
      return unless track

      scrobbler&.now_playing(track[:artist], track[:title])
      terminal_notify(
        message: "#{track[:title]} by #{track[:artist]}",
        title: "Now Playing",
      )
      @console.write(
        [
          display_time(Time.now),
          display_time(Time.now + track[:length]),
          Rainbow(track[:title]).green,
          "by",
          Rainbow(track[:artist]).yellow,
          "from",
          Rainbow(track[:album]).cyan,
          "(#{track[:length] / 60}:#{track[:length] % 60})",
        ].join(" ")
      )
    end

    def track_finished(track)
      return unless track

      scrobbler&.scrobble(track[:artist], track[:title], timestamp: track[:start_time].to_i)
    end

    private

    def display_time(time)
      time.strftime("%I:%M:%S")
    end

    def terminal_notify(message:, title:)
      return if `which terminal-notifier`.empty?

      `terminal-notifier -group vlc -message "#{message}" -title "#{title}"`
    end

    def scrobbler
      Vlcraptor::Scrobbler.load if @preferences.scrobble?
    end
  end
end
