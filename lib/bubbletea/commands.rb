# frozen_string_literal: true

module Bubbletea
  class Command
  end

  class QuitCommand < Command
  end

  class BatchCommand < Command
    attr_reader :commands

    def initialize(commands)
      super()

      @commands = commands
    end
  end

  class TickCommand < Command
    attr_reader :duration, :callback

    def initialize(duration, &callback)
      super()

      @duration = duration
      @callback = callback
    end
  end

  class SendMessage < Command
    attr_reader :message, :delay

    def initialize(message, delay: 0)
      super()

      @message = message
      @delay = delay
    end
  end

  class SequenceCommand < Command
    attr_reader :commands

    def initialize(commands)
      super()

      @commands = commands
    end
  end

  class EnterAltScreenCommand < Command
  end

  class ExitAltScreenCommand < Command
  end

  class SetWindowTitleCommand < Command
    attr_reader :title

    def initialize(title)
      super()

      @title = title
    end
  end

  class PutsCommand < Command
    attr_reader :text

    def initialize(text)
      super()

      @text = text
    end
  end

  class SuspendCommand < Command
  end

  class << self
    def quit
      QuitCommand.new
    end

    def batch(*commands)
      BatchCommand.new(commands.flatten.compact)
    end

    def tick(duration, &)
      TickCommand.new(duration, &)
    end

    def send_message(message, delay: 0)
      SendMessage.new(message, delay: delay)
    end

    def sequence(*commands)
      SequenceCommand.new(commands.flatten.compact)
    end

    def none
      nil
    end

    def enter_alt_screen
      EnterAltScreenCommand.new
    end

    def exit_alt_screen
      ExitAltScreenCommand.new
    end

    def set_window_title(title) # rubocop:disable Naming/AccessorMethodName
      SetWindowTitleCommand.new(title)
    end

    def puts(text)
      PutsCommand.new(text)
    end

    def suspend
      SuspendCommand.new
    end
  end
end
