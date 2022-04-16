# Vlcraptor

This is a queueing daemon for VLC - kind of like `mpd` but nowhere near as flexible or useful.

The player daemon starts two instances of VLC and then uses those to play any tracks placed in the queue.

Why two VLC instances? VLC doesn't support cross fading between tracks so this crossfades by starting the
other VLC instance playing the next track and adjusting volume between both.

At the moment, only mac os is supported - minor changes would be required to allow this to work on linux.

## Installation

You need to install VLC in the default location for mac os (`/Applications/VLC.app`).

`brew install ffmpeg` is required by the `queue` command for extracting tags to place in the queue.

`brew install terminal-notifier` is optional depending if you want terminal notifications when new tracks start.

This gem can be installed with `gem install vlcraptor`.

## Usage

First in one shell session, run `vlcraptor player`. This is the player daemon that controls two instances
of VLC.

Running `vlcraptor` without any parameters will list the available subcommands.

### Adding tracks to the queue

`vlcraptor queue folder_containing_audio_files audio_file.mp3` will place any number of audio files in the
queue and the player should immediately start playing the first track.

### Listing queue contents

`vlcraptor list` will list currently queued tracks with an estimated start time if the player is currently
running and playing a track.

### Media controls

`vlcraptor pause` will pause, `vlcraptor stop` will stop and `vlcraptor play` will resume.

`vlcraptor skip` will fade out the current track and start the next one (unless the queue is empty). 

### Optional features

A number of features can be turned on/off while the player is running that will determine certain behaviour:

`vlcraptor autoplay off` will cause the player to stop and politely wait after the current track has finished.
`vlcraptor autoplay on` and tracks will start playing again.

`vlcraptor crossfade off` will turn off crossfading so new tracks will start once the previous one is
completely finished.

`vlcraptor scrobble on` will turn on last.fm scrobbling - you will require your own application api key
and secret to enable this.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/markryall/vlcraptor.
