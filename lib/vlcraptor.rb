# frozen_string_literal: true

require_relative "vlcraptor/player"
require_relative "vlcraptor/preferences"
require_relative "vlcraptor/queue"
require_relative "vlcraptor/notifiers"

module Vlcraptor
  def self.autoplay(value)
    Vlcraptor::Preferences.new[:autoplay] = value == "on"
  end

  def self.crossfade(value)
    Vlcraptor::Preferences.new[:crossfade] = value == "on"
  end

  def self.player
    player = Vlcraptor::Player.new
    queue = Vlcraptor::Queue.new
    preferences = Vlcraptor::Preferences.new
    notifiers = Vlcraptor::Notifiers.new(preferences)
    track = nil

    loop do
      sleep 0.2

      if player.playing?
        if preferences.skip?
          track = queue.next
          if track
            track[:start_time] = Time.now
            notifiers.track_started(track)
            player.crossfade(track[:path])
          else
            player.fadeout
          end
          next
        end

        if preferences.crossfade? && player.remaining < 5
          notifiers.track_finished(track)
          track = queue.next
          if track
            track[:start_time] = Time.now
            notifiers.track_started(track)
            player.crossfade(track[:path])
          end
        end

        notifiers.track_playing(track)
        next
      end

      next unless preferences.continue?

      notifiers.track_finished(track)
      track = queue.next
      next unless track

      track[:start_time] = Time.now
      notifiers.track_started(track)
      player.play(track[:path])
    end
  rescue Interrupt
    player.cleanup
    puts "Exiting"
  end

  def self.scrobble(value)
    Vlcraptor::Preferences.new[:scrobble] = value == "on"
  end

  def self.skip
    Vlcraptor::Preferences.new[:skip] = true
  end
end
