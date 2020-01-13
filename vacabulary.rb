class Vacabulary

  def initialize(current_path)
    @current_path = current_path
  end

  def add_word(bot, message)
    word = nil
    translate = nil

    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Word:"
    )

    bot.listen do |message|
      word = message.text
      break
    end

    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Translate:"
    )

    bot.listen do |message|
      translate = message.text
      break
    end

    bot.api.send_message(
      chat_id: message.chat.id,
      text: "New word was saved."
    )

    file = File.open(current_path + "/data/" + message.chat.id.to_s + "_new_words.txt", "a")
    file.puts("#{word} #{translate}")
    file.close
  end

  def show_vacabulary

  end

  def learning_mode

  end

  def show_stat

  end

  def notification

  end

  def current_path
    @current_path
  end

end
