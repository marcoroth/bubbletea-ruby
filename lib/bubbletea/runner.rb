# frozen_string_literal: true

module Bubbletea
  # Runner manages the event loop and coordinates between the model and the terminal
  class Runner
    attr_reader :options

    DEFAULT_OPTIONS = {
      alt_screen: false,
      mouse_cell_motion: false,
      mouse_all_motion: false,
      bracketed_paste: false,
      report_focus: false,
      fps: 60,
      input_timeout: 10,
      without_renderer: false,
    }.freeze

    def initialize(model, **options)
      @model = model
      @options = DEFAULT_OPTIONS.merge(options)
      @program = Program.new
      @renderer_id = nil
      @running = false
      @pending_ticks = []
      @width = 80
      @height = 24
      @resize_pending = false
      @previous_winch_handler = nil
      @in_alt_screen = false
    end

    def run
      setup_terminal
      @renderer_id = @program.create_renderer unless @options[:without_renderer]

      update_terminal_size
      @running = true

      new_model, command = @model.init
      @model = new_model if new_model
      process_command(command)

      return unless @running

      handle_message(WindowSizeMessage.new(width: @width, height: @height))

      render
      run_loop
      render
    ensure
      cleanup_terminal
    end

    def send(message)
      @pending_messages ||= []
      @pending_messages << message
    end

    private

    def setup_terminal
      @program.enter_raw_mode
      @program.hide_cursor
      @program.start_input_reader

      if @options[:alt_screen]
        @program.enter_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, true) if @renderer_id
        @in_alt_screen = true
      end

      @program.enable_mouse_cell_motion if @options[:mouse_cell_motion]
      @program.enable_mouse_all_motion if @options[:mouse_all_motion]
      @program.enable_bracketed_paste if @options[:bracketed_paste]
      @program.enable_report_focus if @options[:report_focus]

      setup_resize_handler
    end

    def cleanup_terminal
      restore_resize_handler

      @program.disable_mouse if @options[:mouse_cell_motion] || @options[:mouse_all_motion]
      @program.disable_bracketed_paste if @options[:bracketed_paste]
      @program.disable_report_focus if @options[:report_focus]

      if @in_alt_screen
        @program.exit_alt_screen
      else
        print "\r\n"
      end

      @program.show_cursor
      @program.stop_input_reader
      @program.exit_raw_mode
    end

    def setup_resize_handler
      @previous_winch_handler = Signal.trap("WINCH") do
        @resize_pending = true
        @previous_winch_handler.call if @previous_winch_handler.is_a?(Proc)
      end
    rescue ArgumentError
      # SIGWINCH not supported on this platform
      @previous_winch_handler = nil
    end

    def restore_resize_handler
      if @previous_winch_handler
        Signal.trap("WINCH", @previous_winch_handler)
      else
        Signal.trap("WINCH", "DEFAULT")
      end
    rescue ArgumentError
      # SIGWINCH not supported on this platform
    end

    def update_terminal_size
      size = @program.terminal_size
      return unless size

      @width, @height = size
      @program.renderer_set_size(@renderer_id, @width, @height) if @renderer_id
    end

    def run_loop
      frame_duration = 1.0 / @options[:fps]
      last_frame = Time.now

      while @running
        check_resize
        process_pending_messages

        event = @program.poll_event(@options[:input_timeout])

        if event
          message = Bubbletea.parse_event(event)
          handle_message(message) if message
        end

        process_ticks

        now = Time.now

        if now - last_frame >= frame_duration
          render
          last_frame = now
        end
      end
    end

    def check_resize
      return unless @resize_pending

      @resize_pending = false

      size = @program.terminal_size
      return unless size

      new_width, new_height = size

      return if new_width == @width && new_height == @height

      @width = new_width
      @height = new_height

      @program.renderer_set_size(@renderer_id, @width, @height) if @renderer_id

      handle_message(WindowSizeMessage.new(width: @width, height: @height))
    end

    def process_pending_messages
      return unless @pending_messages&.any?

      messages = @pending_messages
      @pending_messages = []

      messages.each { |message| handle_message(message) }
    end

    def handle_message(message)
      return unless @running

      new_model, command = @model.update(message)
      @model = new_model if new_model
      process_command(command)
    end

    def process_command(command)
      return if command.nil?

      case command
      when QuitCommand
        @running = false

      when BatchCommand
        Thread.new do
          execute_batch_sync(command.commands)
        end

      when SequenceCommand
        Thread.new do
          execute_sequence_sync(command.commands)
        end

      when TickCommand
        schedule_tick(command)

      when SendMessage
        if command.delay.positive?
          schedule_delayed_message(command)
        else
          handle_message(command.message)
        end

      when EnterAltScreenCommand
        @program.enter_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, true) if @renderer_id
        @in_alt_screen = true

      when ExitAltScreenCommand
        @program.exit_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, false) if @renderer_id
        @in_alt_screen = false

      when SetWindowTitleCommand
        Bubbletea._set_window_title(command.title)

      when PutsCommand
        warn "\r#{command.text}\r"

      when SuspendCommand
        suspend_process

      when Proc
        Thread.new do
          result = command.call
          next unless result

          if result.is_a?(Message)
            send(result)
          else
            process_command(result)
          end
        end
      end
    end

    def execute_command_sync(command)
      return if command.nil?

      case command
      when QuitCommand
        @running = false

      when BatchCommand
        execute_batch_sync(command.commands)

      when SequenceCommand
        execute_sequence_sync(command.commands)

      when TickCommand
        schedule_tick(command)

      when SendMessage
        sleep(command.delay) if command.delay.positive?
        handle_message(command.message)

      when EnterAltScreenCommand
        @program.enter_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, true) if @renderer_id
        @in_alt_screen = true

      when ExitAltScreenCommand
        @program.exit_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, false) if @renderer_id
        @in_alt_screen = false

      when SetWindowTitleCommand
        Bubbletea._set_window_title(command.title)

      when PutsCommand
        warn "\r#{command.text}\r"

      when SuspendCommand
        suspend_process

      when Proc
        result = command.call
        return unless result

        if result.is_a?(Message)
          send(result)
        else
          execute_command_sync(result)
        end
      end
    end

    def execute_sequence_sync(commands)
      commands.each do |cmd|
        break unless @running

        execute_command_sync(cmd)
      end
    end

    def execute_batch_sync(commands)
      threads = commands.map do |cmd|
        Thread.new { execute_command_sync(cmd) }
      end

      threads.each(&:join)
    end

    def schedule_tick(tick_command)
      @pending_ticks << {
        at: Time.now + tick_command.duration,
        callback: tick_command.callback,
      }
    end

    def schedule_delayed_message(send_command)
      @pending_ticks << {
        at: Time.now + send_command.delay,
        message: send_command.message,
      }
    end

    def process_ticks
      now = Time.now
      ready, @pending_ticks = @pending_ticks.partition { |tick| tick[:at] <= now }

      ready.each do |tick|
        if tick[:callback]
          result = tick[:callback].call
          handle_message(result) if result
        elsif tick[:message]
          handle_message(tick[:message])
        end
      end
    end

    def suspend_process
      @program.disable_mouse if @options[:mouse_cell_motion] || @options[:mouse_all_motion]
      @program.show_cursor
      @program.stop_input_reader
      @program.exit_raw_mode

      Process.kill("TSTP", Process.pid)

      # When we get here, we've been resumed (SIGCONT was received)
      @program.enter_raw_mode
      @program.hide_cursor
      @program.start_input_reader
      @program.enable_mouse_cell_motion if @options[:mouse_cell_motion]
      @program.enable_mouse_all_motion if @options[:mouse_all_motion]

      handle_message(ResumeMessage.new)
    end

    def render
      return if @options[:without_renderer]
      return unless @renderer_id

      view = @model.view
      @program.render(@renderer_id, view)
    end
  end

  def self.run(model, **options)
    runner = Runner.new(model, **options)
    runner.run
  end
end
