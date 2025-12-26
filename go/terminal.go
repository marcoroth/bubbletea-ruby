package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"os"
	"github.com/charmbracelet/x/ansi"
	"github.com/charmbracelet/x/term"
)

type Terminal struct {
	input         *os.File
	output        *os.File
	previousState *term.State
	rawMode       bool
	altScreen     bool
	cursorHidden  bool
	mouseEnabled  bool
}

//export tea_terminal_init
func tea_terminal_init(programID C.ulonglong) C.int {
	state := getProgram(uint64(programID))
	if state == nil {
		return -1
	}

	state.terminal = &Terminal{
		input:  os.Stdin,
		output: os.Stdout,
	}

	return 0
}

//export tea_terminal_enter_raw_mode
func tea_terminal_enter_raw_mode(programID C.ulonglong) C.int {
	state := getProgram(uint64(programID))
	if state == nil {
		return -1
	}

	if state.terminal == nil {
		state.terminal = &Terminal{
			input:  os.Stdin,
			output: os.Stdout,
		}
	}

	if state.terminal.rawMode {
		return 0
	}

	oldState, err := term.MakeRaw(os.Stdin.Fd())
	if err != nil {
		return -1
	}

	state.terminal.previousState = oldState
	state.terminal.rawMode = true

	return 0
}

//export tea_terminal_exit_raw_mode
func tea_terminal_exit_raw_mode(programID C.ulonglong) C.int {
	state := getProgram(uint64(programID))
	if state == nil || state.terminal == nil {
		return -1
	}

	if !state.terminal.rawMode {
		return 0
	}

	if state.terminal.previousState != nil {
		if err := term.Restore(os.Stdin.Fd(), state.terminal.previousState); err != nil {
			return -1
		}
	}

	state.terminal.rawMode = false
	return 0
}

func (t *Terminal) Restore() {
	if t.previousState != nil {
		term.Restore(os.Stdin.Fd(), t.previousState)
	}
}

//export tea_terminal_enter_alt_screen
func tea_terminal_enter_alt_screen(programID C.ulonglong) {
	state := getProgram(uint64(programID))

	if state == nil || state.terminal == nil {
		return
	}

	if state.terminal.altScreen {
		return
	}

	os.Stdout.WriteString(ansi.SetAltScreenBufferMode)
	os.Stdout.WriteString(ansi.EraseEntireScreen)
	os.Stdout.WriteString(ansi.CursorHomePosition)

	state.terminal.altScreen = true
}

//export tea_terminal_exit_alt_screen
func tea_terminal_exit_alt_screen(programID C.ulonglong) {
	state := getProgram(uint64(programID))

	if state == nil || state.terminal == nil {
		return
	}

	if !state.terminal.altScreen {
		return
	}

	os.Stdout.WriteString(ansi.ResetAltScreenBufferMode)

	state.terminal.altScreen = false
}

//export tea_terminal_hide_cursor
func tea_terminal_hide_cursor(programID C.ulonglong) {
	state := getProgram(uint64(programID))
	if state == nil || state.terminal == nil {
		return
	}

	if state.terminal.cursorHidden {
		return
	}

	os.Stdout.WriteString(ansi.HideCursor)
	state.terminal.cursorHidden = true
}

//export tea_terminal_show_cursor
func tea_terminal_show_cursor(programID C.ulonglong) {
	state := getProgram(uint64(programID))
	if state == nil || state.terminal == nil {
		return
	}

	if !state.terminal.cursorHidden {
		return
	}

	os.Stdout.WriteString(ansi.ShowCursor)
	state.terminal.cursorHidden = false
}

//export tea_terminal_enable_mouse_cell_motion
func tea_terminal_enable_mouse_cell_motion(programID C.ulonglong) {
	state := getProgram(uint64(programID))

	if state == nil || state.terminal == nil {
		return
	}

	os.Stdout.WriteString(ansi.SetButtonEventMouseMode)
	os.Stdout.WriteString(ansi.SetSgrExtMouseMode)

	state.terminal.mouseEnabled = true
}

//export tea_terminal_enable_mouse_all_motion
func tea_terminal_enable_mouse_all_motion(programID C.ulonglong) {
	state := getProgram(uint64(programID))

	if state == nil || state.terminal == nil {
		return
	}

	os.Stdout.WriteString(ansi.SetAnyEventMouseMode)
	os.Stdout.WriteString(ansi.SetSgrExtMouseMode)

	state.terminal.mouseEnabled = true
}

//export tea_terminal_disable_mouse
func tea_terminal_disable_mouse(programID C.ulonglong) {
	state := getProgram(uint64(programID))

	if state == nil || state.terminal == nil {
		return
	}

	if !state.terminal.mouseEnabled {
		return
	}

	os.Stdout.WriteString(ansi.ResetButtonEventMouseMode)
	os.Stdout.WriteString(ansi.ResetAnyEventMouseMode)
	os.Stdout.WriteString(ansi.ResetSgrExtMouseMode)

	state.terminal.mouseEnabled = false
}

//export tea_terminal_enable_bracketed_paste
func tea_terminal_enable_bracketed_paste(programID C.ulonglong) {
	os.Stdout.WriteString(ansi.SetBracketedPasteMode)
}

//export tea_terminal_disable_bracketed_paste
func tea_terminal_disable_bracketed_paste(programID C.ulonglong) {
	os.Stdout.WriteString(ansi.ResetBracketedPasteMode)
}

//export tea_terminal_enable_report_focus
func tea_terminal_enable_report_focus(programID C.ulonglong) {
	os.Stdout.WriteString(ansi.SetFocusEventMode)
}

//export tea_terminal_disable_report_focus
func tea_terminal_disable_report_focus(programID C.ulonglong) {
	os.Stdout.WriteString(ansi.ResetFocusEventMode)
}

//export tea_terminal_get_size
func tea_terminal_get_size(programID C.ulonglong, widthOut *C.int, heightOut *C.int) C.int {
	w, h, err := term.GetSize(os.Stdout.Fd())

	if err != nil {
		return -1
	}

	*widthOut = C.int(w)
	*heightOut = C.int(h)

	state := getProgram(uint64(programID))

	if state != nil {
		state.width = w
		state.height = h
	}

	return 0
}

//export tea_terminal_set_window_title
func tea_terminal_set_window_title(title *C.char) {
	os.Stdout.WriteString(ansi.SetWindowTitle(C.GoString(title)))
}

//export tea_terminal_is_tty
func tea_terminal_is_tty() C.int {
	if term.IsTerminal(os.Stdin.Fd()) {
		return 1
	}

	return 0
}

//export tea_terminal_clear_screen
func tea_terminal_clear_screen() {
	os.Stdout.WriteString(ansi.EraseEntireScreen)
	os.Stdout.WriteString(ansi.CursorHomePosition)
}

//export tea_terminal_erase_line
func tea_terminal_erase_line() {
	os.Stdout.WriteString(ansi.EraseLine(2)) // 2 = erase entire line
}

//export tea_terminal_cursor_home
func tea_terminal_cursor_home() {
	os.Stdout.WriteString(ansi.CursorHomePosition)
}
