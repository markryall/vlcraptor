# frozen_string_literal: true

require "rainbow"
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

  def self.list
    started = Vlcraptor::Preferences.new[:started]
    offset = 0
    Vlcraptor::Queue.each do |track|
      array = []
      array << Time.at(started + offset).strftime("%I:%M:%S") if started
      array += [Rainbow(track[:title]).green, "by", Rainbow(track[:artist]).yellow]
      array += ["from", Rainbow(track[:album]).cyan] if (track[:album] || "").length.positive?
      if track[:length]
        mins = track[:length] / 60
        secs = track[:length] % 60
        array << "(#{mins} minutes and #{secs} seconds)"
      end
      puts array.join(" ")
      offset += track[:length]
    end
  end

  def self.pause
    Vlcraptor::Preferences.new[:pause] = true
  end

  def self.play
    Vlcraptor::Preferences.new[:play] = true
  end

  def self.stop
    Vlcraptor::Preferences.new[:stop] = true
  end

  def self.player
    player = Vlcraptor::Player.new
    queue = Vlcraptor::Queue.new
    preferences = Vlcraptor::Preferences.new
    notifiers = Vlcraptor::Notifiers.new(preferences)
    track = nil
    suspended = false

    loop do
      sleep 0.2

      if preferences.pause?
        player.fadeout
        player.pause
        suspended = true
        notifiers.track_suspended

        next
      end

      if preferences.stop?
        player.fadeout
        player.stop
        suspended = true
        notifiers.track_suspended

        next
      end

      if preferences.play?
        player.fadein
        suspended = false
        notifiers.track_resumed(track, player.time)

        next
      end

      next if suspended

      if player.playing?
        if preferences.skip?
          track = queue.next
          if track
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
            notifiers.track_started(track)
            player.crossfade(track[:path])
          end
        end

        notifiers.track_progress(track, player.remaining)

        next
      end

      next unless preferences.continue?

      notifiers.track_finished(track)
      track = queue.next
      next unless track

      notifiers.track_started(track)
      player.play(track[:path])
    end
  rescue Interrupt
    notifiers.track_suspended
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
