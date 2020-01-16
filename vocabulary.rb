class Vocabulary

  def initialize(file_path, bot, message, answers)
    @file_path = file_path
    @bot = bot
    @message = message
    @answers = answers
    @check = false
    @adminId = '280328567'
    @adminPassword = '1111'

    yamlFile = YAML.load(File.read(@file_path))
    yamlFile = {} if !yamlFile

    if !yamlFile.key?(@message.chat.id)
      yamlFile[@message.chat.id] = {:new_words => {}, :learned_words => {}}
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Hi, #{message.from.first_name}!\nI'm your personal vocabulary-bot who will help in learning the unknown words.\n/help to get all the commands.",
        reply_markup: @answers
      )
      File.write(@file_path, yamlFile.to_yaml)
      @check = true
    end
  end

  def start
    yamlFile = YAML.load(File.read(@file_path))

    if !@check
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Welcome back!\nLet's explore some more unknown words.\n/help to get all the commands.",
        reply_markup: @answers
      )
    end
  end

  def help
    if !@check
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "/add — adding new word.\n/show — your vacabulary.\n/learn — learning mode.\n/stat — show current statistic.\n/save — saving word.\n/end — end learning mode."
      )
    end
  end

  def add_word #todo
    if !@check
      yamlFile = YAML.load(File.read(@file_path))

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
          text: "Translate:"
        )

        @bot.listen do |message|
          translate = message.text.capitalize
          break
        end

        break if translate == "/save" || translate == "Save"

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
  end

  def show_vocabulary #done
    if !@check
      yamlFile = YAML.load(File.read(@file_path))

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
  end

  def learning_mode #todo
    if !@check
      yamlFile = YAML.load(File.read(@file_path))

      cancel = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: "Cancel",
        one_time_keyboard: true
      )

      wordsFromFile = yamlFile[@message.chat.id][:new_words].values

      if wordsFromFile.size == 0
        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "I can't find any new word in your vocabulary.\nYou can add new word /add"
        )
      else
        userWord = nil
        correct = 0
        wrong = 0
        learnedWords = 0

        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "Learning mode",
          reply_markup: cancel
        )

        while true
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

          break if userWord == "/end" || userWord == "Cancel"

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

          break if wordsFromFile.size == 0
        end

          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "Correct: #{correct}\nWrong: #{wrong}\nLearned: #{learnedWords}",
            reply_markup: @answers
          )
      end

        File.write(@file_path, yamlFile.to_yaml)
    end
  end

  def show_stat #done
    if !@check
      yamlFile = YAML.load(File.read(@file_path))

      new_words = yamlFile[@message.chat.id][:new_words].size
      learned_words = yamlFile[@message.chat.id][:learned_words].size

      if new_words == 0 && learned_words == 0
        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "I can't find any new word in your vocabulary.\nYou can add new word /add"
        )
      else
        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "STATISTIC\nNew words: #{new_words}\nLearned words: #{learned_words}"
        )
      end
    end
  end

  def notification #todo
    if !@check

    end
  end

  def removeWord #done
    if !@check
      yamlFile = YAML.load(File.read(@file_path))

      word = nil

      if yamlFile[@message.chat.id][:new_words].size == 0 && yamlFile[@message.chat.id][:learned_words].size == 0
        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "I can't find any new word in your vocabulary.\nYou can add new word /add"
        )
      else
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
    end
  end

  def inputError #done
    if !@check
      yamlFile = YAML.load(File.read(@file_path))

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "I don't understand you...\nUse /help to see all command."
      )
    end
  end

  def adminPanel
    if !@check
      password = nil

      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Enter password:"
      )

      @bot.listen do |message|
        password = message.text
        break
      end

      if password == @adminPassword
        choice = nil

        adminKb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [
            ["Reset Database", "Upload Database"]
          ],
          one_time_keyboard: true
        )

        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "Select what you wnat to do.",
          reply_markup: adminKb
        )

        @bot.listen do |message|
          choice = message.text
          break
        end

        case choice
        when "Delete Database"
          yamlFile = {}

          File.write(@file_path, yamlFile.to_yaml)

          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "Database was reset.",
            reply_markup: @answers
          )
        when "Upload Database"
          @bot.api.send_document(
            chat_id: @adminId,
            document: Faraday::UploadIO.new(@file_path, 'document/yml')
          )

          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "Database was upload.",
            reply_markup: @answers
          )
        else
          @bot.api.send_message(
            chat_id: @message.chat.id,
            text: "I don't understand you...\nUse /help to see all command."
          )
        end

      else
        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "Incorrect password!"
        )
      end
      end
  end

=begin
  def deleteUser
    yamlFile = YAML.load(File.read(@file_path))

    password = nil
    userId = nil

    @bot.api.send_message(
      chat_id: @message.chat.id,
      text: "Enter password:"
    )

    @bot.listen do |message|
      password = message.text
      break
    end

    if password == @adminPassword
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Enter user id:"
      )

      @bot.listen do |message|
        userId = message.text
        break
      end

      puts yamlFile

      puts yamlFile.key?(userId)
      puts yamlFile.include?(userId)

      if yamlFile.include?(userId)
        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "User was remove from DB."
        )

        yamlFile.delete(userId)
        File.write(@file_path, yamlFile.to_yaml)
      else
        @bot.api.send_message(
          chat_id: @message.chat.id,
          text: "User not found."
        )
      end
    else
      @bot.api.send_message(
        chat_id: @message.chat.id,
        text: "Incorrect password!"
      )
    end
  end
=end

end
