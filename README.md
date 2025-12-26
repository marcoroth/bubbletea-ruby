<div align="center">
  <h1>Bubbletea for Ruby</h1>
  <h4>A powerful TUI framework for Ruby.</h4>

  <p>
    <a href="https://rubygems.org/gems/bubbletea"><img alt="Gem Version" src="https://img.shields.io/gem/v/bubbletea"></a>
    <a href="https://github.com/marcoroth/bubbletea-ruby/blob/main/LICENSE.txt"><img alt="License" src="https://img.shields.io/github/license/marcoroth/bubbletea-ruby"></a>
  </p>

  <p>Ruby bindings for <a href="https://github.com/charmbracelet/bubbletea">charmbracelet/bubbletea</a>.<br/>Build beautiful, interactive terminal applications using the Elm Architecture in Ruby.</p>
</div>

## Installation

**Add to your Gemfile:**

```ruby
gem "bubbletea"
```

**Or install directly:**

```bash
gem install bubbletea
```

## Usage

### The Elm Architecture

Bubbletea implements the Elm Architecture pattern with three core methods:

| Method | Description |
|--------|-------------|
| `init` | Returns `[model, command]` - initial state and optional startup command |
| `update(message)` | Returns `[model, command]` - handles messages and updates state |
| `view` | Returns `String` - renders the current state to the terminal |

### Basic Example

**A simple counter:**

```ruby
require "bubbletea"

class Counter
  include Bubbletea::Model

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
      when "q", "ctrl+c"
        [self, Bubbletea.quit]
      when "up", "k"
        @count += 1
        [self, nil]
      when "down", "j"
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
    "Count: #{@count}\n\nPress up/down to change, q to quit"
  end
end

Bubbletea.run(Counter.new)
```

### Messages

Messages are events that trigger updates to your model:

| Message | Description |
|---------|-------------|
| `KeyMessage` | Keyboard input with key type, runes, and modifiers |
| `MouseMessage` | Mouse events with position, button, and action |
| `WindowSizeMessage` | Terminal resize events with width and height |
| `FocusMessage` | Terminal gained focus |
| `BlurMessage` | Terminal lost focus |

**Handling key messages:**

```ruby
def update(message)
  case message
  when Bubbletea::KeyMessage
    case message.to_s
    when "q", "ctrl+c", "esc"
      [self, Bubbletea.quit]
    when "up", "k"
      # handle up
    when "down", "j"
      # handle down
    when "enter"
      # handle enter
    end
  end
end
```

**Key message helpers:**

```ruby
message.enter?     # true if Enter key
message.backspace? # true if Backspace
message.tab?       # true if Tab
message.esc?       # true if Escape
message.space?     # true if Space
message.ctrl?      # true if Ctrl modifier
message.up?        # true if Up arrow
message.down?      # true if Down arrow
message.left?      # true if Left arrow
message.right?     # true if Right arrow
```

### Commands

Commands trigger side effects and return messages:

| Command | Description |
|---------|-------------|
| `Bubbletea.quit` | Exit the program |
| `Bubbletea.tick(duration) { message }` | Schedule a message after delay |
| `Bubbletea.batch(cmd1, cmd2, ...)` | Run multiple commands together |
| `Bubbletea.sequence(cmd1, cmd2, ...)` | Run commands in sequence |
| `Bubbletea.send_message(message)` | Send a message immediately |
| `Bubbletea.enter_alt_screen` | Switch to alternate screen buffer |
| `Bubbletea.exit_alt_screen` | Return to normal screen buffer |
| `Bubbletea.set_window_title(title)` | Set terminal window title |

**Using tick for animations:**

```ruby
class TickMessage < Bubbletea::Message; end

def init
  [self, schedule_tick]
end

def update(message)
  case message
  when TickMessage
    @frame = (@frame + 1) % FRAMES.length
    [self, schedule_tick]
  end
end

def schedule_tick
  Bubbletea.tick(0.1) { TickMessage.new }
end
```

### Run Options

| Option | Description |
|--------|-------------|
| `alt_screen` | Use alternate screen buffer (fullscreen mode) |
| `mouse_cell_motion` | Enable mouse click tracking |
| `mouse_all_motion` | Enable all mouse movement tracking |
| `bracketed_paste` | Enable bracketed paste mode |
| `report_focus` | Report terminal focus/blur events |
| `fps` | Target frames per second (default: 60) |

**Run with options:**

```ruby
Bubbletea.run(MyModel.new,
  alt_screen: true,
  mouse_all_motion: true,
  report_focus: true
)
```

### Styling with Lipgloss

Bubbletea works great with [Lipgloss](https://github.com/marcoroth/lipgloss-ruby) for styling:

```ruby
require "bubbletea"
require "lipgloss"

class StyledApp
  include Bubbletea::Model

  def initialize
    @title_style = Lipgloss::Style.new
      .bold(true)
      .foreground("212")

    @help_style = Lipgloss::Style.new
      .foreground("241")
  end

  def view
    lines = []
    lines << @title_style.render("My App")
    lines << ""
    lines << @help_style.render("Press q to quit")
    lines.join("\n")
  end
end
```

## Development

**Requirements:**
- Go 1.23+
- Ruby 3.2+

**Install dependencies:**

```bash
bundle install
```

**Build the Go library and compile the extension:**

```bash
bundle exec rake compile
```

**Run tests:**

```bash
bundle exec rake test
```

**Run demos:**

The `demo/` directory contains many working examples:

```bash
demo/counter
demo/spinner
demo/test_runner
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcoroth/bubbletea-ruby.

## License

The gem is available as open source under the terms of the MIT License.

## Acknowledgments

This gem wraps [charmbracelet/bubbletea](https://github.com/charmbracelet/bubbletea), part of the excellent [Charm](https://charm.sh) ecosystem.
