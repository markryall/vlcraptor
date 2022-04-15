# frozen_string_literal: true

require_relative "vlcraptor/version"
require_relative "vlcraptor/player"
require_relative "vlcraptor/queue"

module Vlcraptor
  def self.player
    player = Vlcraptor::Player.new
    queue = Vlcraptor::Queue.new

    loop do
      if player.playing?
        if player.length - player.time < 5
          track = queue.next
          player.crossfade(track[:path]) if track
        end

        next
      end

      track = queue.next
      player.play track[:path] if track

      sleep 0.2
    end
  rescue Interrupt
    player.cleanup
    puts "Exiting"
  end
end
