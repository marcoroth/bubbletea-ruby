# frozen_string_literal: true

module Bubbletea
  class Message
  end

  class KeyMessage < Message
    KEY_NULL      = 0
    KEY_CTRL_A    = 1
    KEY_CTRL_B    = 2
    KEY_CTRL_C    = 3
    KEY_CTRL_D    = 4
    KEY_CTRL_E    = 5
    KEY_CTRL_F    = 6
    KEY_CTRL_G    = 7
    KEY_CTRL_H    = 8
    KEY_TAB       = 9
    KEY_CTRL_J    = 10
    KEY_CTRL_K    = 11
    KEY_CTRL_L    = 12
    KEY_ENTER     = 13
    KEY_CTRL_N    = 14
    KEY_CTRL_O    = 15
    KEY_CTRL_P    = 16
    KEY_CTRL_Q    = 17
    KEY_CTRL_R    = 18
    KEY_CTRL_S    = 19
    KEY_CTRL_T    = 20
    KEY_CTRL_U    = 21
    KEY_CTRL_V    = 22
    KEY_CTRL_W    = 23
    KEY_CTRL_X    = 24
    KEY_CTRL_Y    = 25
    KEY_CTRL_Z    = 26
    KEY_ESC       = 27
    KEY_BACKSPACE = 127

    KEY_RUNES     = -1
    KEY_UP        = -2
    KEY_DOWN      = -3
    KEY_RIGHT     = -4
    KEY_LEFT      = -5
    KEY_HOME      = -6
    KEY_END       = -7
    KEY_PGUP      = -8
    KEY_PGDOWN    = -9
    KEY_DELETE    = -10
    KEY_INSERT    = -11
    KEY_F1        = -12
    KEY_F2        = -13
    KEY_F3        = -14
    KEY_F4        = -15
    KEY_F5        = -16
    KEY_F6        = -17
    KEY_F7        = -18
    KEY_F8        = -19
    KEY_F9        = -20
    KEY_F10       = -21
    KEY_F11       = -22
    KEY_F12       = -23
    KEY_SHIFT_TAB = -24
    KEY_SPACE     = -25

    attr_reader :key_type, :runes, :alt, :name

    def initialize(key_type:, runes: [], alt: false, name: nil)
      super()

      @key_type = key_type
      @runes = runes.is_a?(Array) ? runes : []
      @alt = alt
      @name = name || lookup_key_name
    end

    private

    def lookup_key_name
      base_name = if @key_type == KEY_RUNES && char
                    char
                  else
                    go_name = Bubbletea.get_key_name(@key_type)
                    go_name.empty? ? "unknown" : go_name
                  end

      @alt ? "alt+#{base_name}" : base_name
    end

    public

    def to_s
      @name
    end

    def char
      @runes.pack("U*") if @runes.any?
    end

    def ctrl?
      @key_type.between?(0, 31)
    end

    def runes?
      @key_type == KEY_RUNES
    end

    def space?
      @key_type == KEY_SPACE
    end

    def enter?
      @key_type == KEY_ENTER
    end

    def backspace?
      @key_type == KEY_BACKSPACE
    end

    def tab?
      @key_type == KEY_TAB
    end

    def esc?
      @key_type == KEY_ESC
    end

    def up?
      @key_type == KEY_UP
    end

    def down?
      @key_type == KEY_DOWN
    end

    def left?
      @key_type == KEY_LEFT
    end

    def right?
      @key_type == KEY_RIGHT
    end
  end

  class MouseMessage < Message
    BUTTON_NONE       = 0
    BUTTON_LEFT       = 1
    BUTTON_MIDDLE     = 2
    BUTTON_RIGHT      = 3
    BUTTON_WHEEL_UP   = 4
    BUTTON_WHEEL_DOWN = 5

    ACTION_PRESS   = 0
    ACTION_RELEASE = 1
    ACTION_MOTION  = 2

    attr_reader :x, :y, :button, :action, :shift, :alt, :ctrl

    def initialize(x:, y:, button:, action:, shift: false, alt: false, ctrl: false)
      super()

      @x = x
      @y = y
      @button = button
      @action = action
      @shift = shift
      @alt = alt
      @ctrl = ctrl
    end

    def press?
      @action == ACTION_PRESS
    end

    def release?
      @action == ACTION_RELEASE
    end

    def motion?
      @action == ACTION_MOTION
    end

    def wheel?
      @button >= BUTTON_WHEEL_UP
    end

    def left?
      @button == BUTTON_LEFT
    end

    def right?
      @button == BUTTON_RIGHT
    end

    def middle?
      @button == BUTTON_MIDDLE
    end
  end

  class WindowSizeMessage < Message
    attr_reader :width, :height

    def initialize(width:, height:)
      super()

      @width = width
      @height = height
    end
  end

  class FocusMessage < Message
  end

  class BlurMessage < Message
  end

  class QuitMessage < Message
  end

  class ResumeMessage < Message
  end

  def self.parse_event(hash)
    return nil if hash.nil?

    case hash["type"]
    when "key"
      KeyMessage.new(
        key_type: hash["key_type"],
        runes: hash["runes"] || [],
        alt: hash["alt"] || false,
        name: hash["name"]
      )
    when "mouse"
      MouseMessage.new(
        x: hash["x"],
        y: hash["y"],
        button: hash["button"],
        action: hash["action"],
        shift: hash["shift"] || false,
        alt: hash["alt"] || false,
        ctrl: hash["ctrl"] || false
      )
    when "focus"
      FocusMessage.new
    when "blur"
      BlurMessage.new
    end
  end
end
