# frozen_string_literal: true

module Pyxis
  class DiscordClient
    LOG_CHANNEL = 1478849342101000222

    COLOR_MAPPING = {
      info: '#4caf50',
      warn: '#ff8000',
      error: '#f44336',
    }.freeze

    attr_reader :bot

    def initialize
      @bot = Discordrb::Bot.new(token: Pyxis::Environment.discord_bot_token)
    end

    def send_notification(message, severity = :info)
      embed = Discordrb::Webhooks::Embed.new(description: message, color: COLOR_MAPPING[severity])

      bot.send_message(LOG_CHANNEL, nil, false, [embed])
    end
  end
end
