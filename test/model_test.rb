# frozen_string_literal: true

require "test_helper"

class TestModel < Minitest::Spec
  class SimpleModel
    include Bubbletea::Model

    attr_reader :count

    def initialize
      @count = 0
    end

    def init
      [self, nil]
    end

    def update(message)
      case message
      when Bubbletea::KeyMessage
        case message.to_s
        when "q"
          [self, Bubbletea.quit]
        when "up"
          @count += 1
          [self, nil]
        when "down"
          @count -= 1
          [self, nil]
        else
          [self, nil]
        end
      else
        [self, nil]
      end
    end

    def view
      "Count: #{@count}"
    end
  end

  class ModelWithCommand
    include Bubbletea::Model

    def init
      [self, Bubbletea.quit]
    end

    def update(_msg)
      [self, nil]
    end

    def view
      "Test"
    end
  end

  class ModelWithBatchCommand
    include Bubbletea::Model

    attr_reader :messages_received

    def initialize
      @messages_received = []
    end

    def init
      tick1 = Bubbletea.tick(0.1) { :tick1 }
      tick2 = Bubbletea.tick(0.2) { :tick2 }
      [self, Bubbletea.batch(tick1, tick2)]
    end

    def update(message)
      @messages_received << message
      [self, nil]
    end

    def view
      "Messages: #{@messages_received.length}"
    end
  end

  it "model init returns model and cmd" do
    model = SimpleModel.new
    result = model.init
    assert_instance_of Array, result
    assert_equal 2, result.length
    assert_instance_of SimpleModel, result[0]
    assert_nil result[1]
  end

  it "model init with command" do
    model = ModelWithCommand.new
    result = model.init
    assert_instance_of Bubbletea::QuitCommand, result[1]
  end

  it "model update returns model and command" do
    model = SimpleModel.new
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [120])
    result = model.update(message)
    assert_instance_of Array, result
    assert_equal 2, result.length
  end

  it "model update with quit" do
    model = SimpleModel.new
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [113], name: "q")
    _, command = model.update(message)
    assert_instance_of Bubbletea::QuitCommand, command
  end

  it "model update modifies state" do
    model = SimpleModel.new
    assert_equal 0, model.count

    up_msg = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP)
    model.update(up_msg)
    assert_equal 1, model.count

    model.update(up_msg)
    assert_equal 2, model.count

    down_msg = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN)
    model.update(down_msg)
    assert_equal 1, model.count
  end

  it "model view returns string" do
    model = SimpleModel.new
    view = model.view
    assert_instance_of String, view
    assert_equal "Count: 0", view
  end

  it "model view reflects state" do
    model = SimpleModel.new
    up_msg = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP)
    model.update(up_msg)
    assert_equal "Count: 1", model.view
  end

  it "default model module methods" do
    # Test that including Model provides default implementations
    klass = Class.new { include Bubbletea::Model }
    model = klass.new

    # Default init returns [self, nil]
    result = model.init
    assert_equal model, result[0]
    assert_nil result[1]

    # Default update returns [self, nil]
    result = model.update(:any_msg)
    assert_equal model, result[0]
    assert_nil result[1]

    # Default view returns empty string
    assert_equal "", model.view
  end

  it "model with window size msg" do
    klass = Class.new do
      include Bubbletea::Model

      attr_reader :width, :height

      def initialize
        @width = 0
        @height = 0
      end

      def update(message)
        case message
        when Bubbletea::WindowSizeMessage
          @width = message.width
          @height = message.height
        end
        [self, nil]
      end
    end

    model = klass.new
    message = Bubbletea::WindowSizeMessage.new(width: 100, height: 50)
    model.update(message)
    assert_equal 100, model.width
    assert_equal 50, model.height
  end
end
