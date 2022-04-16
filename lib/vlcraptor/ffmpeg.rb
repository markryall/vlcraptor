# frozen_string_literal: true

module Vlcraptor
  class Ffmpeg
    attr_reader(
      :title,
      :album,
      :artist,
      :albumartist,
      :time,
      :date,
      :track,
      :puid,
      :mbartistid,
      :mbalbumid,
      :mbalbumartistid,
      :asin,
    )

    CHARS = " `';&!()$".scan(/./)

    def initialize(path)
      @path = CHARS.inject(path) { |s, char| s.gsub(char) { "\\#{char}" } }
      `ffmpeg -i #{@path} 2>&1`.each_line do |line|
        l = line.chomp
        case l
        when "  Metadata:"
          @meta = {}
        else
          if @meta
            m = / *: */.match l
            add_meta m.pre_match.strip.downcase.to_sym, m.post_match.strip if m
          end
        end
      end

      @title = tag :title, :tit2
      @album = tag :album, :talb
      @artist = tag :artist, :tpe1, :tpe2
      @albumartist = tag :album_artist, :tso2
      @time = to_duration tag :duration
      @date = tag :date, :tdrc, :tyer
      @track = tag :track, :trck
      @puid = tag :"musicip puid"
      @mbartistid = tag :musicbrainz_artistid, :"musicbrainz artist id"
      @mbalbumid = tag :musicbrainz_albumid, :"musicbrainz album id"
      @mbalbumartistid = tag :musicbrainz_albumartistid, :"musicbrainz album artist id"
      @asin = tag :asin
    end

    def add_meta(key, value)
      @meta[key] ||= value
    end

    def tag(*names)
      names.each { |name| return @meta[name] if @meta[name] }
      nil
    end

    private

    def to_duration(s)
      return nil unless s

      first, = s.split ","
      hours, minutes, seconds = first.split ":"
      seconds.to_i + (minutes.to_i * 60) + (hours.to_i * 60 * 60)
    end
  end
end
