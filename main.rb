current_path = File.dirname(__FILE__)

require 'yaml'
require 'telegram/bot'
require './vocabulary.rb'

TOKEN = '1010614089:AAFoDp88jQlKfIzPoWi5U_V7Q215U8xOnOY'

file_path = current_path + '/users.yml'

Telegram::Bot::Client.run(TOKEN) do |vocabularyBot|
  vocabularyBot.listen do |mainMessage|

    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: [
        ["Add new word", "Show vocabulary"],
        ["Learning mode", "Show statistic"],
        ["Notification", "Remove word"]
      ],
      one_time_keyboard: true
    )

    vocabulary = Vocabulary.new(file_path, vocabularyBot, mainMessage, answers)

    case mainMessage.text
    when '/start'
      vocabulary.start
    when '/help'
      vocabulary.help
    when '/add', "Add new word"
      vocabulary.add_word
    when '/show', "Show vocabulary"
      vocabulary.show_vocabulary
    when '/learn', "Learning mode"
      vocabulary.learning_mode
    when '/stat', "Show statistic"
      vocabulary.show_stat
    when '/notification', "Notification"
      vocabulary.notification
    when '/remove', "Remove word"
      vocabulary.removeWord
    else
      vocabulary.inputError
    end
  end
end
