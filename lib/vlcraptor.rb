# frozen_string_literal: true

require "curses"
require "rainbow"
require_relative "vlcraptor/player"
require_relative "vlcraptor/player_controller"
require_relative "vlcraptor/preferences"
require_relative "vlcraptor/queue"
require_relative "vlcraptor/notifiers"
require_relative "vlcraptor/scrobbler"

module Vlcraptor
  def self.autoplay(value)
    Vlcraptor::Preferences.new[:autoplay] = value == "on"
  end

  def self.clear
    Vlcraptor::Queue.clear
  end

  def self.crossfade(value)
    Vlcraptor::Preferences.new[:crossfade] = value == "on"
  end

  def self.history
    history_path = "#{File.expand_path("~")}/.player_history"
    `touch #{history_path}`
    system("cat #{history_path}")
  end

  def self.list
    started = Vlcraptor::Preferences.new[:started]
    offset = 0
    index = 0
    Vlcraptor::Queue.each do |track|
      array = [Rainbow(index.to_s).magenta]
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
      index += 1
    end
  end

  def self.pause
    Vlcraptor::Preferences.new[:pause] = true
  end

  def self.play
    Vlcraptor::Preferences.new[:play] = true
  end

  def self.player
    Curses.init_screen
    Curses.start_color
    Curses.curs_set(0)
    Curses.noecho

    Curses.init_pair(0, 0, 0) # white
    Curses.init_pair(2, 2, 0) # green
    Curses.init_pair(5, 5, 0) # magenta
    Curses.init_pair(6, 6, 0) # cyan
    Curses.init_pair(8, 8, 0) # grey
    Curses.init_pair(9, 9, 0) # orange
    Curses.init_pair(11, 11, 0) # yellow

    player_controller = Vlcraptor::PlayerController.new
    window = Curses::Window.new(0, 0, 1, 2)
    window.nodelay = true

    loop do
      window.setpos(0, 0)

      player_controller.next.each do |pair|
        window.attron(Curses.color_pair(pair.first)) { window << pair.last }
        Curses.clrtoeol
      end
      (window.maxy - window.cury).times { window.deleteln }
      window.refresh

      case window.getch.to_s
      when " "
        pause
      when "n"
        skip
      when "p"
        play
      when "s"
        stop
      when "q"
        break
      end

      sleep 0.2
    end
  ensure
    player_controller.cleanup
    Curses.close_screen
  end

  def self.remove(index)
    Vlcraptor::Queue.remove(index) { list }
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
    preferences = Vlcraptor::Preferences.new
    preferences[:scrobble] = value == "on"
    scrobbler = Vlcraptor::Scrobbler.load if preferences.scrobble?
    preferences[:scrobble] = false unless scrobbler
  end

  def self.skip
    Vlcraptor::Preferences.new[:skip] = true
  end

  def self.stop
    Vlcraptor::Preferences.new[:stop] = true
  end

  def self.swap(args)
    a, b = *args
    Vlcraptor::Queue.swap(a, b) { list }
  end
end
