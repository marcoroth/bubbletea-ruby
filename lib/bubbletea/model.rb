# frozen_string_literal: true

module Bubbletea
  # Model module that provides the Elm Architecture interface.
  # Include this module in your model class and implement:
  #   - init: Returns [model, command] - initial state and optional command
  #   - update(message): Returns [model, command] - new state and optional command
  #   - view: Returns String - the current view to render
  #
  # Example:
  #   class Counter
  #     include Bubbletea::Model
  #
  #     attr_reader :count
  #
  #     def initialize
  #       @count = 0
  #     end
  #
  #     def init
  #       [self, nil]
  #     end
  #
  #     def update(message)
  #       case message
  #       when Bubbletea::KeyMessage
  #         case message.to_s
  #         when "q", "ctrl+c"
  #           [self, Bubbletea.quit]
  #         when "up", "k"
  #           @count += 1
  #           [self, nil]
  #         when "down", "j"
  #           @count -= 1
  #           [self, nil]
  #         else
  #           [self, nil]
  #         end
  #       else
  #         [self, nil]
  #       end
  #     end
  #
  #     def view
  #       "Count: #{@count}\n\nPress up/down to change, q to quit"
  #     end
  #   end
  #
  module Model
    def init
      [self, nil]
    end

    def update(_message)
      [self, nil]
    end

    def view
      ""
    end
  end
end
