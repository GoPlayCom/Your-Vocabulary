=begin
puts "1 [+] add word to your vacabulary.\n2 [+] show vacabulary.\n3 [+] learning mode.\n4 [+] statistic.\n5 [+] exit."
print "add first word yo your vacabulary. --> "
puts "STATISTIC"
puts "YOUR VACABULARY"
puts "LEARNING MODE"
puts "NEW WORDS"
puts "LEARNED WORDS"
puts "word --> "
puts "translate --> "
puts "Are you sure?\n1 [+] yes\n2 [+] no"
=end

current_path = File.dirname(__FILE__)

require 'yaml'
require 'telegram/bot'
require './vacabulary.rb'

TOKEN = '911434810:AAGwi0QAMP3vV_asGIV6YuKdtpjvhwvZW64'

file_path = current_path + '/users.yml'

Telegram::Bot::Client.run(TOKEN) do |vacabularyBot|
  vacabularyBot.listen do |mainMessage|

    vacabulary = Vacabulary.new(file_path, vacabularyBot, mainMessage)

=begin
    unless File.exist?(current_path + "/data/" + message.chat.id.to_s + "_new_words.txt")
      File.new(current_path + "/data/" + message.chat.id.to_s + "_new_words.txt", "a")
    end
=end

    case mainMessage.text
    when '/start', '/start start'

      yamlFile = YAML.load(File.read(file_path))

      unless yamlFile.key?(mainMessage.chat.id)
        yamlFile[mainMessage.chat.id] = {:new_words => {}, :learned_words => {}}
        File.write(file_path, yamlFile.to_yaml)
        vacabularyBot.api.send_message(
          chat_id: mainMessage.chat.id,
          text: "Вітання!\nЯ твій персональний бот який поможе в вивчені англійських слів.\n/help для отримання всіх команд."
        )
      else
        vacabularyBot.api.send_message(
          chat_id: mainMessage.chat.id,
          text: "З поверненням!\nДавай вивчимо ще декілька невідомих слів.\n/help для отримання всіх команд."
        )
      end

=begin
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
=end

    when '/help'
      vacabularyBot.api.send_message(
        chat_id: mainMessage.chat.id,
        text: "/add - adding new word.\n/show - your vacabulary.\n/learn - learning mode.\n/stat - show current statistic.\n\n/notification - learning by notification [on|off]."
      )
    when '/add'
      vacabulary.add_word
    when '/show'
      vacabulary.show_vacabulary
    when '/learn'
      vacabulary.learning_mode
    when '/stat'
      vacabulary.show_stat
    when '/notification'

    when '/abortt'
      abort
    else
      vacabularyBot.api.send_message(
        chat_id: mainMessage.chat.id,
        text: "I don't understand you...\nUse /help to see all command."
      )
    end
  end
end
