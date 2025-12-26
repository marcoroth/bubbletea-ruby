# frozen_string_literal: true

require "test_helper"

class TestKeyMsg < Minitest::Spec
  it "key msg with runes" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97])
    assert_equal Bubbletea::KeyMessage::KEY_RUNES, message.key_type
    assert_equal [97], message.runes
    assert_equal "a", message.char
    assert_equal "a", message.to_s
    assert message.runes?
  end

  it "key msg with alt" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97], alt: true)
    assert message.alt
    assert_equal "alt+a", message.to_s
  end

  it "key msg enter" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_ENTER)
    assert message.enter?
    assert_equal "enter", message.to_s
    refute message.runes?
  end

  it "key msg backspace" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_BACKSPACE)
    assert message.backspace?
    assert_equal "backspace", message.to_s
  end

  it "key msg tab" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_TAB)
    assert message.tab?
    assert_equal "tab", message.to_s
  end

  it "key msg escape" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_ESC)
    assert message.esc?
    assert_equal "esc", message.to_s
  end

  it "key msg ctrl c" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_CTRL_C)
    assert message.ctrl?
    assert_equal "ctrl+c", message.to_s
  end

  it "key msg arrows" do
    up = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP)
    down = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN)
    left = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_LEFT)
    right = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RIGHT)

    assert up.up?
    assert down.down?
    assert left.left?
    assert right.right?

    assert_equal "up", up.to_s
    assert_equal "down", down.to_s
    assert_equal "left", left.to_s
    assert_equal "right", right.to_s
  end

  it "key msg space" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_SPACE)
    assert message.space?
    assert_equal "space", message.to_s
  end

  it "key msg function keys" do
    f1 = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_F1)
    f12 = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_F12)

    assert_equal "f1", f1.to_s
    assert_equal "f12", f12.to_s
  end

  it "key msg custom name" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97], name: "custom")
    assert_equal "custom", message.to_s
  end

  it "key msg unicode char" do
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [128_522])
    assert_equal "😊", message.char
  end
end

class TestMouseMsg < Minitest::Spec
  it "mouse msg creation" do
    message = Bubbletea::MouseMessage.new(x: 10, y: 20, button: Bubbletea::MouseMessage::BUTTON_LEFT, action: Bubbletea::MouseMessage::ACTION_PRESS)
    assert_equal 10, message.x
    assert_equal 20, message.y
    assert_equal Bubbletea::MouseMessage::BUTTON_LEFT, message.button
    assert_equal Bubbletea::MouseMessage::ACTION_PRESS, message.action
  end

  it "mouse msg press" do
    message = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_LEFT, action: Bubbletea::MouseMessage::ACTION_PRESS)
    assert message.press?
    refute message.release?
    refute message.motion?
  end

  it "mouse msg release" do
    message = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_LEFT, action: Bubbletea::MouseMessage::ACTION_RELEASE)
    assert message.release?
    refute message.press?
  end

  it "mouse msg motion" do
    message = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_NONE, action: Bubbletea::MouseMessage::ACTION_MOTION)
    assert message.motion?
  end

  it "mouse msg buttons" do
    left = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_LEFT, action: Bubbletea::MouseMessage::ACTION_PRESS)
    right = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_RIGHT, action: Bubbletea::MouseMessage::ACTION_PRESS)
    middle = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_MIDDLE, action: Bubbletea::MouseMessage::ACTION_PRESS)

    assert left.left?
    assert right.right?
    assert middle.middle?
  end

  it "mouse msg wheel" do
    wheel_up = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_WHEEL_UP, action: Bubbletea::MouseMessage::ACTION_PRESS)
    wheel_down = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_WHEEL_DOWN, action: Bubbletea::MouseMessage::ACTION_PRESS)

    assert wheel_up.wheel?
    assert wheel_down.wheel?
  end

  it "mouse msg modifiers" do
    message = Bubbletea::MouseMessage.new(x: 0, y: 0, button: Bubbletea::MouseMessage::BUTTON_LEFT,
                                          action: Bubbletea::MouseMessage::ACTION_PRESS, shift: true, alt: true, ctrl: true)
    assert message.shift
    assert message.alt
    assert message.ctrl
  end
end

class TestWindowSizeMsg < Minitest::Spec
  it "window size msg creation" do
    message = Bubbletea::WindowSizeMessage.new(width: 80, height: 24)
    assert_equal 80, message.width
    assert_equal 24, message.height
  end
end

class TestFocusBlurMessage < Minitest::Spec
  it "focus message" do
    message = Bubbletea::FocusMessage.new
    assert_instance_of Bubbletea::FocusMessage, message
    assert_kind_of Bubbletea::Message, message
  end

  it "blur message" do
    message = Bubbletea::BlurMessage.new
    assert_instance_of Bubbletea::BlurMessage, message
    assert_kind_of Bubbletea::Message, message
  end
end

class TestQuitMessage < Minitest::Spec
  it "quit message" do
    message = Bubbletea::QuitMessage.new
    assert_instance_of Bubbletea::QuitMessage, message
    assert_kind_of Bubbletea::Message, message
  end
end

class TestParseEvent < Minitest::Spec
  it "parse nil" do
    assert_nil Bubbletea.parse_event(nil)
  end

  it "parse key event" do
    event = { "type" => "key", "key_type" => Bubbletea::KeyMessage::KEY_RUNES, "runes" => [97], "alt" => false }
    message = Bubbletea.parse_event(event)
    assert_instance_of Bubbletea::KeyMessage, message
    assert_equal "a", message.to_s
  end

  it "parse key event with alt" do
    event = { "type" => "key", "key_type" => Bubbletea::KeyMessage::KEY_RUNES, "runes" => [97], "alt" => true }
    message = Bubbletea.parse_event(event)
    assert message.alt
  end

  it "parse key event with name" do
    event = { "type" => "key", "key_type" => Bubbletea::KeyMessage::KEY_UP, "name" => "up" }
    message = Bubbletea.parse_event(event)
    assert_equal "up", message.to_s
  end

  it "parse mouse event" do
    event = { "type" => "mouse", "x" => 10, "y" => 20, "button" => 1, "action" => 0 }
    message = Bubbletea.parse_event(event)
    assert_instance_of Bubbletea::MouseMessage, message
    assert_equal 10, message.x
    assert_equal 20, message.y
  end

  it "parse mouse event with modifiers" do
    event = { "type" => "mouse", "x" => 0, "y" => 0, "button" => 1, "action" => 0, "shift" => true, "alt" => true,
              "ctrl" => true }
    message = Bubbletea.parse_event(event)
    assert message.shift
    assert message.alt
    assert message.ctrl
  end

  it "parse focus event" do
    event = { "type" => "focus" }
    message = Bubbletea.parse_event(event)
    assert_instance_of Bubbletea::FocusMessage, message
  end

  it "parse blur event" do
    event = { "type" => "blur" }
    message = Bubbletea.parse_event(event)
    assert_instance_of Bubbletea::BlurMessage, message
  end

  it "parse unknown event" do
    event = { "type" => "unknown" }
    message = Bubbletea.parse_event(event)
    assert_nil message
  end
end
