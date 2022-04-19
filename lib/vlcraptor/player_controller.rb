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
      %w[one two three four five]
    end

    def cleanup
      @player.cleanup
    end
  end
end
