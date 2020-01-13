current_path = File.dirname(__FILE__)

require 'yaml'
require 'telegram/bot'
require './vacabulary.rb'

TOKEN = '911434810:AAGwi0QAMP3vV_asGIV6YuKdtpjvhwvZW64'

vacabulary = Vacabulary.new(current_path)

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|

=begin
    unless File.exist?(current_path + "/data/" + message.chat.id.to_s + "_new_words.txt")
      File.new(current_path + "/data/" + message.chat.id.to_s + "_new_words.txt", "a")
    end
=end

    case message.text
    when '/start', '/start start'
      if File.exist?(current_path + "/data/" + message.chat.id.to_s + "_new_words.txt")
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "З поверненням!\nДавай вивчимо ще декілька невідомих слів.\n/help для отримання всіх команд."
        )
      else
        File.new(current_path + "/data/" + message.chat.id.to_s + "_new_words.txt", "a")
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Вітання!\nЯ твій персональний бот який поможе в вивчені англійських слів.\n/help для отримання всіх команд."
        )
      end
    when '/help'
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "/add - adding new word.\n/show - your vacabulary.\n/learn - learning mode.\n/stat - show current statistic.\n\n/notification - learning by notification [on|off]."
      )
    when '/add'
      vacabulary.add_word(bot, message)
    when '/show'

    when '/learn'

    when '/stat'

    when '/notification'

    when '/aborts'
      abort
    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "I don't understand you...\nUse /help to see all command."
      )
    end
  end
end
