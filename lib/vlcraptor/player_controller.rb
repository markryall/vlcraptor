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
      @notifiers = Vlcraptor::Notifiers.new
      @track = nil
      @suspended = false
    end

    def next
      return on_play if @preferences.play? && @suspended
      return on_pause if @preferences.pause? && !@suspended
      return on_stop if @preferences.stop? && !@suspended
      return build if @suspended
      return when_playing if @track && @player.playing?
      return when_auto if @preferences.continue?

      when_manual
    end

    def cleanup
      @notifiers.track_suspended
      @player.fadeout
      @player.cleanup
    end

    private

    def on_pause
      suspend("Now Paused", :pause)
    end

    def on_stop
      suspend("Now Stopped", :stop)
    end

    def suspend(status, method)
      @player.fadeout
      @player.send(method)
      @status = status
      @suspended = true
      @notifiers.track_suspended
      build
    end

    def on_play
      @player.fadein
      @suspended = false
      @notifiers.track_resumed(@track, @player.time)
      when_playing_track(@player.remaining)
    end

    def when_playing
      return on_skip if @preferences.skip?
      return on_crossfade if @preferences.crossfade? && @player.remaining < 5

      when_playing_track(@player.remaining)
    end

    def on_skip
      @track = @queue.next
      @notifiers.track_suspended
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
      @status = "Now Playing"
      remaining_color = remaining < 30 ? 9 : 5
      build(
        [2, @track[:title]],
        [0, "\n"],
        [0, "by "],
        [11, @track[:artist]],
        [0, "\n"],
        [0, "from "],
        [6, @track[:album]],
        [0, "\n"],
        [remaining_color, duration(remaining)],
        [0, " of "],
        [0, duration(@track[:length])],
        [0, " remaining\n"],
      )
    end

    def when_empty
      @status = "Now Waiting"
      build
    end

    def when_manual
      @status = "Now Waiting"
      build
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

    def build(*extra)
      autoplay = @preferences[:autoplay] ? "+" : "-"
      crossfade = @preferences[:crossfade] ? "+" : "-"
      scrobble = @preferences[:scrobble] ? "+" : "-"
      [
        [0, display_time(Time.now)],
        [0, "\n"],
        [0, @status],
        [0, "\n"],
        [0, "#{Vlcraptor::Queue.length} queued tracks"],
        [0, "\n"],
        [8, "#{autoplay}autoplay #{crossfade}crossfade #{scrobble}scrobble"],
        [0, "\n"],
      ] + extra
    end
  end
end
