# frozen_string_literal: true

require_relative "player"
require_relative "preferences"
require_relative "queue"
require_relative "notifiers"

module Vlcraptor
  class PlayerController
    def initialize
      @player = Vlcraptor::Player.new
      @preferences = Vlcraptor::Preferences.new
      @queue = Vlcraptor::Queue.new
      @notifiers = Vlcraptor::Notifiers.new(use_console: false)
      @track = nil
      @suspended = false
    end

    def lines
      return on_pause if @preferences.pause?
      return on_stop if @preferences.stop?
      return on_play if @preferences.play?
      return when_suspended if @suspended
      return when_playing if @player.playing?
      return when_auto if @preferences.continue?

      when_manual
    end

    def cleanup
      @player.cleanup
    end

    private

    def on_pause
      @player.fadeout
      @player.pause
      @suspended = true
      @message = "Paused"
      @notifiers.track_suspended
      when_suspended
    end

    def on_stop
      @player.fadeout
      @player.stop
      @suspended = true
      @message = "Stopped"
      @notifiers.track_suspended
      when_suspended
    end

    def on_play
      @player.fadein
      @suspended = false
      @message = ""
      @notifiers.track_resumed(@track, @player.time)
      when_playing_track(@player.remaining)
    end

    def when_suspended
      [display_time(Time.now), @message]
    end

    def when_playing
      return on_skip if @preferences.skip?
      return on_crossfade if @preferences.crossfade? && @player.remaining < 5

      @notifiers.track_progress(@track, @player.remaining)
      when_playing_track(@player.remaining)
    end

    def on_skip
      @track = @queue.next
      if @track
        @notifiers.track_started(@track)
        @player.crossfade(@track[:path])
        when_playing_track(@player.remaining)
      else
        @player.fadeout
        when_empty
      end
    end

    def on_crossfade
      @notifiers.track_finished(@track)
      @track = @queue.next
      if @track
        @notifiers.track_started(@track)
        @player.crossfade(@track[:path])
        when_playing_track(@player.remaining)
      else
        @player.fadeout
        when_empty
      end
    end

    def when_auto
      @notifiers.track_finished(@track)
      @track = @queue.next
      return when_empty unless @track

      @notifiers.track_started(@track)
      @player.play(@track[:path])
      when_playing_track(@track[:length])
    end

    def when_playing_track(remaining)
      [
        display_time(Time.now),
        "Playing",
        @track[:title],
        @track[:artist],
        @track[:album],
        "Duration #{duration(@track[:length])}",
        "Remaining #{duration(remaining)}",
      ]
    end

    def when_empty
      [display_time(Time.now), "Queue is empty"]
    end

    def when_manual
      [display_time(Time.now), "Autoplay is off"]
    end

    def display_time(time)
      time.strftime("%I:%M:%S")
    end

    def duration(seconds)
      if seconds > 60
        "#{seconds / 60}m and #{seconds % 60}s"
      else
        "#{seconds}s"
      end
    end
  end
end
