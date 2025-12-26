# frozen_string_literal: true

require "test_helper"

class TestRunner < Minitest::Spec
  class DummyModel
    include Bubbletea::Model

    def view
      "Test"
    end
  end

  it "runner initialization" do
    model = DummyModel.new
    runner = Bubbletea::Runner.new(model)

    assert_equal model, runner.instance_variable_get(:@model)
    assert_equal 80, runner.instance_variable_get(:@width)
    assert_equal 24, runner.instance_variable_get(:@height)
    refute runner.instance_variable_get(:@running)
    refute runner.instance_variable_get(:@resize_pending)
  end

  it "runner default options" do
    model = DummyModel.new
    runner = Bubbletea::Runner.new(model)
    options = runner.options

    refute options[:alt_screen]
    refute options[:mouse_cell_motion]
    refute options[:mouse_all_motion]
    refute options[:bracketed_paste]
    refute options[:report_focus]
    assert_equal 60, options[:fps]
    assert_equal 10, options[:input_timeout]
  end

  it "runner custom options" do
    model = DummyModel.new
    runner = Bubbletea::Runner.new(model, alt_screen: true, mouse_all_motion: true, fps: 30)
    options = runner.options

    assert options[:alt_screen]
    assert options[:mouse_all_motion]
    assert_equal 30, options[:fps]
  end

  it "runner send method" do
    model = DummyModel.new
    runner = Bubbletea::Runner.new(model)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97])
    runner.send(message)

    pending_messages = runner.instance_variable_get(:@pending_messages)
    assert_equal 1, pending_messages.length
    assert_equal message, pending_messages[0]
  end

  it "runner send multiple messages" do
    model = DummyModel.new
    runner = Bubbletea::Runner.new(model)

    msg1 = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97])
    msg2 = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [98])
    runner.send(msg1)
    runner.send(msg2)

    pending_messages = runner.instance_variable_get(:@pending_messages)
    assert_equal 2, pending_messages.length
  end
end

class TestRunnerCommandProcessing < Minitest::Spec
  class TrackingModel
    include Bubbletea::Model

    attr_reader :messages

    def initialize
      @messages = []
    end

    def update(message)
      @messages << message
      [self, nil]
    end

    def view
      "Messages: #{@messages.length}"
    end
  end

  def setup
    @model = TrackingModel.new
    @runner = Bubbletea::Runner.new(@model)
    @runner.instance_variable_set(:@running, true)
  end

  it "process quit command" do
    @runner.__send__(:process_command, Bubbletea.quit)
    refute @runner.instance_variable_get(:@running)
  end

  it "process batch command" do
    msg1 = :msg1
    msg2 = :msg2

    cmd = Bubbletea.batch(
      Bubbletea.send_message(msg1),
      Bubbletea.send_message(msg2)
    )

    @runner.__send__(:process_command, cmd)
    sleep 0.05

    assert_equal 2, @model.messages.length
    assert_includes @model.messages, msg1
    assert_includes @model.messages, msg2
  end

  it "process sequence command" do
    msg1 = :msg1
    msg2 = :msg2

    cmd = Bubbletea.sequence(
      Bubbletea.send_message(msg1),
      Bubbletea.send_message(msg2)
    )

    @runner.__send__(:process_command, cmd)
    sleep 0.05

    assert_equal 2, @model.messages.length
  end

  it "process send message command" do
    message = :test_message
    command = Bubbletea.send_message(message)

    @runner.__send__(:process_command, command)

    assert_equal 1, @model.messages.length
    assert_equal message, @model.messages[0]
  end

  it "process tick command" do
    cmd = Bubbletea.tick(0.1) { :tick_result }

    @runner.__send__(:process_command, cmd)

    pending_ticks = @runner.instance_variable_get(:@pending_ticks)

    assert_equal 1, pending_ticks.length
    assert pending_ticks[0][:callback]
    assert_equal :tick_result, pending_ticks[0][:callback].call
  end

  it "process nil command" do
    @runner.__send__(:process_command, nil)
  end
end
