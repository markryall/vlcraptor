# frozen_string_literal: true

require_relative "vlcraptor/player"
require_relative "vlcraptor/preferences"
require_relative "vlcraptor/queue"

module Vlcraptor
  def self.skip
    Vlcraptor::Preferences.new[:skip] = true
  end

  def self.player
    player = Vlcraptor::Player.new
    queue = Vlcraptor::Queue.new
    preferences = Vlcraptor::Preferences.new

    loop do
      sleep 0.2

      if player.playing?
        if preferences.skip? || (preferences.crossfade? && player.remaining < 5)
          track = queue.next
          player.crossfade(track[:path]) if track
        end

        next
      end

      next unless preferences.continue?

      track = queue.next
      player.play track[:path] if track
    end
  rescue Interrupt
    player.cleanup
    puts "Exiting"
  end
end
