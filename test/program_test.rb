# frozen_string_literal: true

require "test_helper"

class TestProgram < Minitest::Spec
  it "program creation" do
    program = Bubbletea::Program.new
    assert_instance_of Bubbletea::Program, program
  end

  it "program terminal size" do
    program = Bubbletea::Program.new
    size = program.terminal_size

    return unless size

    assert_instance_of Array, size
    assert_equal 2, size.length
    assert_kind_of Integer, size[0]
    assert_kind_of Integer, size[1]
  end

  it "program create renderer" do
    program = Bubbletea::Program.new
    renderer_id = program.create_renderer
    assert_kind_of Integer, renderer_id
    assert renderer_id.positive?
  end

  it "program string width" do
    program = Bubbletea::Program.new

    assert_equal 5, program.string_width("hello")
    assert_equal 0, program.string_width("")

    width = program.string_width("test")
    assert_equal 4, width
  end

  it "program responds to terminal methods" do
    program = Bubbletea::Program.new

    assert_respond_to program, :enter_raw_mode
    assert_respond_to program, :exit_raw_mode
    assert_respond_to program, :enter_alt_screen
    assert_respond_to program, :exit_alt_screen
    assert_respond_to program, :hide_cursor
    assert_respond_to program, :show_cursor
    assert_respond_to program, :enable_mouse_cell_motion
    assert_respond_to program, :enable_mouse_all_motion
    assert_respond_to program, :disable_mouse
    assert_respond_to program, :enable_bracketed_paste
    assert_respond_to program, :disable_bracketed_paste
    assert_respond_to program, :enable_report_focus
    assert_respond_to program, :disable_report_focus
  end

  it "program responds to input methods" do
    program = Bubbletea::Program.new

    assert_respond_to program, :start_input_reader
    assert_respond_to program, :stop_input_reader
    assert_respond_to program, :read_raw_input
    assert_respond_to program, :poll_event
  end

  it "program responds to renderer methods" do
    program = Bubbletea::Program.new

    assert_respond_to program, :create_renderer
    assert_respond_to program, :render
    assert_respond_to program, :renderer_set_size
    assert_respond_to program, :renderer_set_alt_screen
    assert_respond_to program, :renderer_clear
  end
end
