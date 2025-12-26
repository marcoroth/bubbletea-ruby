# frozen_string_literal: true

require "test_helper"

class TestBubbletea < Minitest::Spec
  it "has a version number" do
    refute_nil ::Bubbletea::VERSION
  end

  it "has correct version format" do
    assert_match(/v\d+\.\d+\.\d+/, Bubbletea.version)
  end

  it "has tty? method" do
    assert_respond_to Bubbletea, :tty?
  end

  it "has run method" do
    assert_respond_to Bubbletea, :run
  end

  it "quit returns quit command" do
    command = Bubbletea.quit
    assert_instance_of Bubbletea::QuitCommand, command
  end

  it "batch returns batch command" do
    command = Bubbletea.batch(Bubbletea.quit, Bubbletea.quit)
    assert_instance_of Bubbletea::BatchCommand, command
    assert_equal 2, command.commands.length
  end

  it "batch flattens and compacts" do
    command = Bubbletea.batch([Bubbletea.quit, nil], nil, Bubbletea.quit)
    assert_instance_of Bubbletea::BatchCommand, command
    assert_equal 2, command.commands.length
  end

  it "tick returns tick command" do
    command = Bubbletea.tick(0.5) { "tick" }
    assert_instance_of Bubbletea::TickCommand, command
    assert_equal 0.5, command.duration
    assert_equal "tick", command.callback.call
  end

  it "send_message returns send message command" do
    message = Bubbletea::KeyMessage.new(key_type: 113, runes: [113])
    command = Bubbletea.send_message(message)
    assert_instance_of Bubbletea::SendMessage, command
    assert_equal message, command.message
    assert_equal 0, command.delay
  end

  it "send_message with delay" do
    message = Bubbletea::KeyMessage.new(key_type: 113, runes: [113])
    command = Bubbletea.send_message(message, delay: 1.0)
    assert_equal 1.0, command.delay
  end

  it "sequence returns sequence command" do
    command = Bubbletea.sequence(Bubbletea.quit, Bubbletea.quit)
    assert_instance_of Bubbletea::SequenceCommand, command
    assert_equal 2, command.commands.length
  end

  it "none returns nil" do
    assert_nil Bubbletea.none
  end
end
