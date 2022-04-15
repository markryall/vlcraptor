# frozen_string_literal: true

require_relative "vlcraptor/player"
require_relative "vlcraptor/preferences"
require_relative "vlcraptor/queue"
require_relative "vlcraptor/scrobbler"

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
    scrobbler = Vlcraptor::Scrobbler.load if preferences.scrobble?
    track = nil
    start_time = Time.now.to_i

    loop do
      sleep 0.2

      if player.playing?
        skipping = preferences.skip?
        track = nil if skipping
        if skipping || (preferences.crossfade? && player.remaining < 5)
          scrobbler&.scrobble(track[:artist], track[:title], timestamp: start_time) if track
          track = queue.next
          if track
            start_time = Time.now.to_i
            scrobbler&.now_playing(track[:artist], track[:title])
            player.crossfade(track[:path])
          end
        end

        next
      end

      next unless preferences.continue?

      scrobbler&.scrobble(track[:artist], track[:title], timestamp: start_time) if track
      track = queue.next
      next unless track

      start_time = Time.now.to_i
      scrobbler&.now_playing(track[:artist], track[:title])
      player.crossfade(track[:path])
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
