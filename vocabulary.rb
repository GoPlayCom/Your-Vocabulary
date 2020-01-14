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

    puts yamlFile.to_s

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
  end

  def help
    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "/add — adding new word.\n/show — your vacabulary.\n/learn — learning mode.\n/stat — show current statistic.\n/notification — learning by notification [on|off].\n/cancel — canxel adding word.\n/end — end learning mode."
    )
  end

  def add_word
    yamlFile = YAML.load(File.read(@file_path))

    if yamlFile
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
    end

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

      break if word == "/cancel" || word == "Save"

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Translate:"
      )

      @bot.listen do |message|
        translate = message.text.capitalize
        break
      end

      break if translate == "/cancel" || word == "Save"

      puts yamlFile
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

    puts yamlFile

    if yamlFile
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
    else
      yamlFile = {}
      vocabulary = "I can't find any word in your vocabulary.\nYou can add new word /add"
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      File.write(@file_path, yamlFile.to_yaml)
    end

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: vocabulary
    )

    puts vocabulary
  end

  def learning_mode
    yamlFile = YAML.load(File.read(@file_path))
    puts yamlFile.to_s

    wordsFromFile = yamlFile[@message.chat.id][:new_words].values
    puts wordsFromFile.to_s

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
        text: "Learning mode [ON]"
      )

      while true

        break if wordsFromFile.size == 0

        translatedWord = wordsFromFile.sample
        puts translatedWord.to_s
        puts wordsFromFile.index(translatedWord)

        correctWord = yamlFile[@message.chat.id][:new_words].key(translatedWord)
        puts correctWord.to_s

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

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Learning mode [OFF]",
        reply_markup: @answers
      )

    end

=begin
    yamlFile = YAML.load(File.read(@file_path))
    fileWords = yamlFile[@message.chat.id][:new_words].values
    puts fileWords.size
    userWord = ""
    correct = 0
    wrong = 0

    if fileWords.size == 0
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "I can't find any word in your vacabulary.\nYou can add new word /add"
      )
    else
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Learning mode [ON]"
      )

      while userWord != "/end" || fileWords.size != 0

        translate = fileWords.sample

        puts translate.to_s

        correctWord = yamlFile[@message.chat.id][:new_words].key(translate)
        puts correctWord

        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: translate[0]
        )

        @bot.listen do |message|
          userWord = message.text
          break
        end

        if userWord == correctWord

          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "Right!"
          )

          yamlFile[@message.chat.id][:new_words][correctWord[1]] = translate[1] + 1
          correct += 1
        else

          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "Wrong!\nCorrect word: #{correctWord}"
          )

          wrong += 1
        end


        puts fileWords
        puts fileWords.shift(fileWords.index(translate))
        puts userWord
        puts fileWords

      end

      File.write(@file_path, yamlFile.to_yaml)

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Learning mode [OFF]"
      )
    end
=end
  end

  def show_stat
    yamlFile = YAML.load(File.read(@file_path))

    new_words = yamlFile[@message.chat.id][:new_words].size
    learned_words = yamlFile[@message.chat.id][:learned_words].size

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "STATISTIC\nNew words: #{new_words}\nLearned words: #{learned_words}"
    )
  end

  def notification

  end

  def inputError
    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "I don't understand you...\nUse /help to see all command."
    )
  end
end