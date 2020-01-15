class Vocabulary
  attr_reader :file_path, :bot, :message

  def initialize(file_path, bot, message, answers)
    @file_path = file_path
    @bot = bot
    @message = message
    @answers = answers
  end

  def start
    yamlFile = YAML.load(File.read(@file_path))

    puts "[+]New user: #{@message.chat.id}"

    yamlFile = {} if !yamlFile

    unless yamlFile.key?(@message.chat.id)
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Вітання!\nЯ твій персональний бот який поможе в вивчені англійських слів.\n/help для отримання всіх команд.",
        reply_markup: @answers
      )
    else
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "З поверненням!\nДавай вивчимо ще декілька невідомих слів.\n/help для отримання всіх команд.",
        reply_markup: @answers
      )
    end
  end

  def help
    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "/add — adding new word.\n/show — your vacabulary.\n/learn — learning mode.\n/stat — show current statistic.\n/notification — learning by notification [on|off].\n/cancel — cancel adding word.\n/end — end learning mode."
    )
  end

  def add_word
    yamlFile = YAML.load(File.read(@file_path))

    yamlFile = {} if !yamlFile

    if !yamlFile.key?(@message.chat.id)
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
    end

    cancel = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: "Cancel",
      one_time_keyboard: true
    )

    save = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: "Save",
      one_time_keyboard: true
    )

    word = nil
    translate = nil

    while true
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Word:",
        reply_markup: save
      )

      @bot.listen do |message|
        word = message.text.capitalize
        break
      end

      break if word == "/save" || word == "Save"

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Translate:",
        reply_markup: cancel
      )

      @bot.listen do |message|
        translate = message.text.capitalize
        break
      end

      break if translate == "/cancel" || translate == "Cancel"

      yamlFile[@message.chat.id][:new_words][word] = [translate, 0]

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "New word was added."
      )
    end

    File.write(@file_path, yamlFile.to_yaml)

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "All words was saved to your vocabulary.",
      reply_markup: @answers
    )
  end

  def show_vocabulary
    yamlFile = YAML.load(File.read(@file_path))

    yamlFile = {} if !yamlFile

    if !yamlFile.key?(@message.chat.id)
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
    end

    if yamlFile[@message.chat.id][:new_words].size == 0
      vocabulary = "I can't find any words in your vocabulary.\n"
    else
      vocabulary = "New words\n— — — — — — — — — —\n"

      yamlFile[@message.chat.id][:new_words].each do |word, translate|
         vocabulary += word + "  —  " + translate[0] + "\n"
      end
    end

    if yamlFile[@message.chat.id][:learned_words].size == 0
      vocabulary += "\nYou haven't learned a word."
    else
      vocabulary += "\nLearned words\n— — — — — — — — — —\n"

      yamlFile[@message.chat.id][:learned_words].each do |word, translate|
        vocabulary += word + "  —  " + translate[0] + "\n"
      end
    end

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: vocabulary
    )
  end

  def learning_mode
    yamlFile = YAML.load(File.read(@file_path))

    yamlFile = {} if !yamlFile

    if !yamlFile.key?(@message.chat.id)
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
    end

    wordsFromFile = yamlFile[@message.chat.id][:new_words].values
    userWord = nil
    correct = 0
    wrong = 0
    learnedWords = 0

    if wordsFromFile.size == 0
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "I can't find any new word in your vocabulary.\nYou can add new word /add"
      )
    else
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Learning mode"
      )

      while true
        break if wordsFromFile.size == 0

        translatedWord = wordsFromFile.sample
        correctWord = yamlFile[@message.chat.id][:new_words].key(translatedWord)

        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: translatedWord[0]
        )

        @bot.listen do |message|
          userWord = message.text
          break
        end

        break if userWord == "/end"

        if userWord.capitalize == correctWord
          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "Right!"
          )

          yamlFile[@message.chat.id][:new_words][correctWord][1] += 1
          correct += 1

          if yamlFile[@message.chat.id][:new_words][correctWord][1] == 5
            yamlFile[@message.chat.id][:learned_words][correctWord] = translatedWord
            yamlFile[@message.chat.id][:new_words].delete(correctWord)
            learnedWords += 1
          end
        else
          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "Wrong!\nCorrect word: #{correctWord}"
          )

          yamlFile[@message.chat.id][:new_words][correctWord][1] = 0
          wrong += 1
        end
        wordsFromFile.delete_at(wordsFromFile.index(translatedWord)).to_s
      end

      File.write(@file_path, yamlFile.to_yaml)

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Correct: #{correct}\nWrong: #{wrong}\nLearned: #{learnedWords}"
      )
    end
  end

  def show_stat
    yamlFile = YAML.load(File.read(@file_path))

    yamlFile = {} if !yamlFile

    if !yamlFile.key?(@message.chat.id)
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
    end

    new_words = yamlFile[@message.chat.id][:new_words].size
    learned_words = yamlFile[@message.chat.id][:learned_words].size

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "STATISTIC\nNew words: #{new_words}\nLearned words: #{learned_words}"
    )
  end

  def notification
    yamlFile = YAML.load(File.read(@file_path))

    yamlFile = {} if !yamlFile

    if !yamlFile.key?(@message.chat.id)
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
    end
  end

  def removeWord
    yamlFile = YAML.load(File.read(@file_path))
    word = nil

    yamlFile = {} if !yamlFile

    if !yamlFile.key?(@message.chat.id)
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
    end

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "Word that you want remove:"
    )

    @bot.listen do |message|
      word = message.text.capitalize
      break
    end

    if yamlFile[@message.chat.id][:new_words].key?(word)
      yamlFile[@message.chat.id][:new_words].delete(word)
      File.write(@file_path, yamlFile.to_yaml)
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "\'#{word}\' was removed from your vocabulary."
      )
    elsif yamlFile[@message.chat.id][:learned_words].key?(word)
      yamlFile[@message.chat.id][:learned_words].delete(word)
      File.write(@file_path, yamlFile.to_yaml)
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "\'#{word}\' was removed from your vocabulary."
      )
    else
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "I can't find this word in your vocabulary."
      )
    end
  end

  def inputError
    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "I don't understand you...\nUse /help to see all command."
    )
  end
end
