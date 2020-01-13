class Vacabulary
  attr_reader :file_path, :bot, :message

  def initialize(file_path, bot, message)
    @file_path = file_path
    @bot = bot
    @message = message
  end

  def add_word
    word = nil
    translate = nil

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "Word:"
    )

    @bot.listen do |message|
      word = message.text.capitalize
      break
    end

    return 0 if word == "/cancel"

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "Translate:"
    )

    @bot.listen do |message|
      translate = message.text.capitalize
      break
    end

    return 0 if translate == "/cancel"

    yamlFile = YAML.load(File.read(@file_path))
    puts yamlFile
    yamlFile[@message.chat.id][:new_words][word] = [translate, 0]
    File.write(@file_path, yamlFile.to_yaml)

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "New word was saved."
    )
  end

  def show_vacabulary
    yamlFile = YAML.load(File.read(@file_path))

    if yamlFile[@message.chat.id][:new_words].size == 0
      vacabulary = "You have not any word in your vacabulary.\n"
    else
      vacabulary = "New words\n- - - - - - - - - -\n"

      yamlFile[@message.chat.id][:new_words].each do |word, translate|
         vacabulary += word.ljust(20 - word.length) + translate[0] + "\n"
      end
    end

    if yamlFile[@message.chat.id][:learned_words].size == 0
      vacabulary += "\nYou dont learned any word."
    else
      vacabulary += "\nLearned words\n- - - - - - - - - - - - -\n"

      yamlFile[@message.chat.id][:learned_words].each do |word, translate|
        vacabulary += word.ljust(20) + translate[0] + "\n"
      end
    end

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: vacabulary
    )

    puts vacabulary
  end

  def learning_mode
    yamlFile = YAML.load(File.read(@file_path))
    puts yamlFile.to_s

    wordsFromFile = yamlFile[@message.chat.id][:new_words].values
    puts wordsFromFile.to_s

    userWord = nil
    correct = 0
    wrong = 0

    if wordsFromFile.size == 0
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "I can't find any word in your vacabulary.\nYou can add new word /add"
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
          end

        else
          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "Wrong!\nCorrect word: #{correctWord}"
          )

          wrong += 1
        end

        wordsFromFile.delete_at(wordsFromFile.index(translatedWord)).to_s

      end

      File.write(@file_path, yamlFile.to_yaml)


      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Correct: #{correct}\nWrong: #{wrong}"
      )

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Learning mode [OFF]"
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
end
