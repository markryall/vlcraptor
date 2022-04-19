# frozen_string_literal: true

require "curses"
require "rainbow"
require_relative "vlcraptor/player"
require_relative "vlcraptor/player_controller"
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

  def self.history
    system("cat #{File.expand_path("~")}/.player_history")
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

  def self.player
    player = Vlcraptor::Player.new
    queue = Vlcraptor::Queue.new
    preferences = Vlcraptor::Preferences.new
    notifiers = Vlcraptor::Notifiers.new
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

  def self.player_new
    Curses.init_screen
    Curses.start_color
    Curses.curs_set(0)
    Curses.noecho

    Curses.init_pair(1, 2, 0) # Curses::COLOR_GREEN on Curses::COLOR_BLACK

    player_controller = Vlcraptor::PlayerController.new
    window = Curses::Window.new(0, 0, 1, 2)
    window.nodelay = true

    loop do
      window.setpos(0, 0)

      lines = player_controller.lines

      lines.each do |line|
        window.attron(Curses.color_pair(1)) { window << line }
        Curses.clrtoeol
        window << "\n"
      end
      (window.maxy - window.cury).times { window.deleteln }
      window.refresh

      str = window.getch.to_s
      case str
      when "q"
        break
      end

      sleep 0.1
    end
  ensure
    player_controller.cleanup
    Curses.close_screen
  end

  def self.queue(paths)
    paths.each do |path|
      if File.file?(path)
        Vlcraptor::Queue.add(path)
      else
        Dir.glob("#{path}/**/*.*").each do |child_path|
          Vlcraptor::Queue.add(child_path)
        end
      end
    end
  end

  def self.scrobble(value)
    Vlcraptor::Preferences.new[:scrobble] = value == "on"
  end

  def self.skip
    Vlcraptor::Preferences.new[:skip] = true
  end

  def self.stop
    Vlcraptor::Preferences.new[:stop] = true
  end
end
