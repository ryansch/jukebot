require 'dotenv'
Dotenv.load
require 'slack-ruby-bot'
require 'pry'

require_relative 'includes/bot_regex'
require_relative 'includes/string_monkeypatch'

require_relative 'commands/what_is_playing'
require_relative 'commands/find_music'
require_relative 'commands/play_music'
require_relative 'commands/next_music'
require_relative 'commands/queue_music'
require_relative 'commands/single_commands'
require_relative 'commands/find_radio'
require_relative 'commands/play_radio'

require_relative 'services/sonos_service'
require_relative 'services/spotify_service'
require_relative 'services/tune_in_service'

class JukeBot < SlackRubyBot::Bot
  def self.api
    @api ||= JukeBotService::Sonos.new
  end

  def self.spotify
    @spotify ||= JukeBotService::Spotify.new
  end

  def self.tunein
    @tunein ||= JukeBotService::TuneIn.new
  end

  volume_regex = /volume (?<volume>.*)/i
  match BotRegex.new(volume_regex) do |client, data, match|
    volume = match[:volume]
    if volume.number?
      api.change_group_volume(volume)
      response = "Set the volume to #{volume} :mega:"
    else
      response = "How am I supposed to change the volume to #{volume}?"
    end
    client.say(text: response, channel: data.channel)
  end

  change_room_regex = /change\sroom\s(?:to )?(?<room>.*)$/i
  match BotRegex.new(change_room_regex) do |client, data, match|
    if api.change_room(match[:room])
      response = "Ok, room set to #{match[:room]}."
    else
      response = "Sorry, it doesn't look like that room exists."
      response += "Try #{api.rooms.join(', ')}"
    end
    client.say(text: response, channel: data.channel)
  end

  say_regex = /say\s(?<words>.*)$/i
  match BotRegex.new(say_regex) do |_client, _data, match|
    api.say(text: match[:words])
  end
end

JukeBot.run
