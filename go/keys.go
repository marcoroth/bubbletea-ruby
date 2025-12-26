package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"encoding/json"
	"unicode/utf8"
	"unsafe"
)

type KeyType int

const (
	KeyNull      KeyType = 0
	KeyCtrlA     KeyType = 1
	KeyCtrlB     KeyType = 2
	KeyCtrlC     KeyType = 3
	KeyCtrlD     KeyType = 4
	KeyCtrlE     KeyType = 5
	KeyCtrlF     KeyType = 6
	KeyCtrlG     KeyType = 7
	KeyCtrlH     KeyType = 8
	KeyTab       KeyType = 9
	KeyCtrlJ     KeyType = 10
	KeyCtrlK     KeyType = 11
	KeyCtrlL     KeyType = 12
	KeyEnter     KeyType = 13
	KeyCtrlN     KeyType = 14
	KeyCtrlO     KeyType = 15
	KeyCtrlP     KeyType = 16
	KeyCtrlQ     KeyType = 17
	KeyCtrlR     KeyType = 18
	KeyCtrlS     KeyType = 19
	KeyCtrlT     KeyType = 20
	KeyCtrlU     KeyType = 21
	KeyCtrlV     KeyType = 22
	KeyCtrlW     KeyType = 23
	KeyCtrlX     KeyType = 24
	KeyCtrlY     KeyType = 25
	KeyCtrlZ     KeyType = 26
	KeyEsc       KeyType = 27
	KeyBackspace KeyType = 127
)

const (
	KeyRunes    KeyType = -1
	KeyUp       KeyType = -2
	KeyDown     KeyType = -3
	KeyRight    KeyType = -4
	KeyLeft     KeyType = -5
	KeyHome     KeyType = -6
	KeyEnd      KeyType = -7
	KeyPgUp     KeyType = -8
	KeyPgDown   KeyType = -9
	KeyDelete   KeyType = -10
	KeyInsert   KeyType = -11
	KeyF1       KeyType = -12
	KeyF2       KeyType = -13
	KeyF3       KeyType = -14
	KeyF4       KeyType = -15
	KeyF5       KeyType = -16
	KeyF6       KeyType = -17
	KeyF7       KeyType = -18
	KeyF8       KeyType = -19
	KeyF9       KeyType = -20
	KeyF10      KeyType = -21
	KeyF11      KeyType = -22
	KeyF12      KeyType = -23
	KeyShiftTab KeyType = -24
	KeySpace    KeyType = -25
)

type KeyEvent struct {
	Type    string `json:"type"`     // "key"
	KeyType int    `json:"key_type"` // KeyType value
	Runes   []rune `json:"runes"`    // Characters for KeyRunes
	Alt     bool   `json:"alt"`      // Alt modifier
	Name    string `json:"name"`     // Human-readable name
}

type MouseEvent struct {
	Type    string `json:"type"`   // "mouse"
	X       int    `json:"x"`      // Column (0-based)
	Y       int    `json:"y"`      // Row (0-based)
	Button  int    `json:"button"` // Button number
	Action  int    `json:"action"` // 0=press, 1=release, 2=motion
	Shift   bool   `json:"shift"`
	Alt     bool   `json:"alt"`
	Ctrl    bool   `json:"ctrl"`
}

type ResizeEvent struct {
	Type   string `json:"type"` // "resize"
	Width  int    `json:"width"`
	Height int    `json:"height"`
}

type FocusEvent struct {
	Type  string `json:"type"`  // "focus" or "blur"
	Focus bool   `json:"focus"` // true for focus, false for blur
}

var keyNames = map[KeyType]string{
	KeyNull:      "ctrl+@",
	KeyCtrlA:     "ctrl+a",
	KeyCtrlB:     "ctrl+b",
	KeyCtrlC:     "ctrl+c",
	KeyCtrlD:     "ctrl+d",
	KeyCtrlE:     "ctrl+e",
	KeyCtrlF:     "ctrl+f",
	KeyCtrlG:     "ctrl+g",
	KeyCtrlH:     "ctrl+h",
	KeyTab:       "tab",
	KeyCtrlJ:     "ctrl+j",
	KeyCtrlK:     "ctrl+k",
	KeyCtrlL:     "ctrl+l",
	KeyEnter:     "enter",
	KeyCtrlN:     "ctrl+n",
	KeyCtrlO:     "ctrl+o",
	KeyCtrlP:     "ctrl+p",
	KeyCtrlQ:     "ctrl+q",
	KeyCtrlR:     "ctrl+r",
	KeyCtrlS:     "ctrl+s",
	KeyCtrlT:     "ctrl+t",
	KeyCtrlU:     "ctrl+u",
	KeyCtrlV:     "ctrl+v",
	KeyCtrlW:     "ctrl+w",
	KeyCtrlX:     "ctrl+x",
	KeyCtrlY:     "ctrl+y",
	KeyCtrlZ:     "ctrl+z",
	KeyEsc:       "esc",
	KeyBackspace: "backspace",
	KeyRunes:     "runes",
	KeyUp:        "up",
	KeyDown:      "down",
	KeyRight:     "right",
	KeyLeft:      "left",
	KeyHome:      "home",
	KeyEnd:       "end",
	KeyPgUp:      "pgup",
	KeyPgDown:    "pgdown",
	KeyDelete:    "delete",
	KeyInsert:    "insert",
	KeyF1:        "f1",
	KeyF2:        "f2",
	KeyF3:        "f3",
	KeyF4:        "f4",
	KeyF5:        "f5",
	KeyF6:        "f6",
	KeyF7:        "f7",
	KeyF8:        "f8",
	KeyF9:        "f9",
	KeyF10:       "f10",
	KeyF11:       "f11",
	KeyF12:       "f12",
	KeyShiftTab:  "shift+tab",
	KeySpace:     "space",
}

var escapeSequences = map[string]KeyType{
	"\x1b[A":     KeyUp,
	"\x1b[B":     KeyDown,
	"\x1b[C":     KeyRight,
	"\x1b[D":     KeyLeft,
	"\x1b[H":     KeyHome,
	"\x1b[F":     KeyEnd,
	"\x1b[1~":    KeyHome,
	"\x1b[4~":    KeyEnd,
	"\x1b[5~":    KeyPgUp,
	"\x1b[6~":    KeyPgDown,
	"\x1b[2~":    KeyInsert,
	"\x1b[3~":    KeyDelete,
	"\x1bOP":     KeyF1,
	"\x1bOQ":     KeyF2,
	"\x1bOR":     KeyF3,
	"\x1bOS":     KeyF4,
	"\x1b[15~":   KeyF5,
	"\x1b[17~":   KeyF6,
	"\x1b[18~":   KeyF7,
	"\x1b[19~":   KeyF8,
	"\x1b[20~":   KeyF9,
	"\x1b[21~":   KeyF10,
	"\x1b[23~":   KeyF11,
	"\x1b[24~":   KeyF12,
	"\x1b[Z":     KeyShiftTab,
	"\x1b[1;2A":  KeyType(-100), // Shift+Up (placeholder)
	"\x1b[1;2B":  KeyType(-101), // Shift+Down
	"\x1b[1;2C":  KeyType(-102), // Shift+Right
	"\x1b[1;2D":  KeyType(-103), // Shift+Left
	"\x1b[1;5A":  KeyType(-104), // Ctrl+Up
	"\x1b[1;5B":  KeyType(-105), // Ctrl+Down
	"\x1b[1;5C":  KeyType(-106), // Ctrl+Right
	"\x1b[1;5D":  KeyType(-107), // Ctrl+Left
}

func ParseInput(data []byte) (int, string) {
	if len(data) == 0 {
		return 0, ""
	}

	if len(data) >= 3 {
		if data[0] == 0x1b && data[1] == '[' {
			if data[2] == 'I' {
				// Focus gained
				event := FocusEvent{Type: "focus", Focus: true}
				jsonBytes, _ := json.Marshal(event)

				return 3, string(jsonBytes)
			}
			if data[2] == 'O' {
				// Focus lost
				event := FocusEvent{Type: "blur", Focus: false}
				jsonBytes, _ := json.Marshal(event)

				return 3, string(jsonBytes)
			}
		}
	}

	// Check for mouse events (SGR format: ESC [ < ... M or m)
	if len(data) >= 6 && data[0] == 0x1b && data[1] == '[' && data[2] == '<' {
		consumed, mouseEvent := parseMouseSGR(data)
		if consumed > 0 {
			jsonBytes, _ := json.Marshal(mouseEvent)
			return consumed, string(jsonBytes)
		}
	}

	if data[0] == 0x1b && len(data) > 1 {
		for seq, keyType := range escapeSequences {
			if len(data) >= len(seq) && string(data[:len(seq)]) == seq {
				name := keyNames[keyType]

				if name == "" {
					name = "unknown"
				}

				event := KeyEvent{
					Type:    "key",
					KeyType: int(keyType),
					Runes:   nil,
					Alt:     false,
					Name:    name,
				}

				jsonBytes, _ := json.Marshal(event)

				return len(seq), string(jsonBytes)
			}
		}

		// Alt + key (ESC followed by a character)
		if len(data) >= 2 && data[1] >= 32 && data[1] < 127 {
			r := rune(data[1])

			event := KeyEvent{
				Type:    "key",
				KeyType: int(KeyRunes),
				Runes:   []rune{r},
				Alt:     true,
				Name:    "alt+" + string(r),
			}

			jsonBytes, _ := json.Marshal(event)

			return 2, string(jsonBytes)
		}

		event := KeyEvent{
			Type:    "key",
			KeyType: int(KeyEsc),
			Runes:   nil,
			Alt:     false,
			Name:    "esc",
		}

		jsonBytes, _ := json.Marshal(event)

		return 1, string(jsonBytes)
	}

	// Control characters (0-31, 127)
	if data[0] < 32 || data[0] == 127 {
		keyType := KeyType(data[0])
		name := keyNames[keyType]

		if name == "" {
			name = "ctrl+?"
		}

		event := KeyEvent{
			Type:    "key",
			KeyType: int(keyType),
			Runes:   nil,
			Alt:     false,
			Name:    name,
		}

		jsonBytes, _ := json.Marshal(event)

		return 1, string(jsonBytes)
	}

	if data[0] == ' ' {
		event := KeyEvent{
			Type:    "key",
			KeyType: int(KeySpace),
			Runes:   []rune{' '},
			Alt:     false,
			Name:    "space",
		}
		jsonBytes, _ := json.Marshal(event)
		return 1, string(jsonBytes)
	}

	// Regular character (UTF-8)
	r, size := utf8.DecodeRune(data)

	if r == utf8.RuneError && size == 1 {
		return 1, "" // Invalid UTF-8, skip byte
	}

	event := KeyEvent{
		Type:    "key",
		KeyType: int(KeyRunes),
		Runes:   []rune{r},
		Alt:     false,
		Name:    string(r),
	}
	jsonBytes, _ := json.Marshal(event)
	return size, string(jsonBytes)
}

// parseMouseSGR parses SGR mouse format: ESC [ < Cb ; Cx ; Cy M/m
func parseMouseSGR(data []byte) (int, MouseEvent) {
	// Format: \x1b[<button;x;y(M|m)
	// M = press/motion, m = release
	if len(data) < 6 || data[0] != 0x1b || data[1] != '[' || data[2] != '<' {
		return 0, MouseEvent{}
	}

	// Find the terminating M or m
	endIndex := -1

	for i := 3; i < len(data) && i < 32; i++ {
		if data[i] == 'M' || data[i] == 'm' {
			endIndex = i
			break
		}
	}

	if endIndex == -1 {
		return 0, MouseEvent{} // Incomplete sequence
	}

	params := string(data[3:endIndex])
	var button, x, y int
	n, err := parseInts(params, &button, &x, &y)

	if err != nil || n != 3 {
		return 0, MouseEvent{}
	}

	shift := (button & 4) != 0
	alt := (button & 8) != 0
	ctrl := (button & 16) != 0
	motion := (button & 32) != 0
	buttonNum := button & 3

	action := 0 // press

	if data[endIndex] == 'm' {
		action = 1 // release
	} else if motion {
		action = 2 // motion
	}

	if (button & 64) != 0 {
		if buttonNum == 0 {
			buttonNum = 4 // wheel up
		} else if buttonNum == 1 {
			buttonNum = 5 // wheel down
		}
	}

	return endIndex + 1, MouseEvent{
		Type:   "mouse",
		X:      x - 1,
		Y:      y - 1,
		Button: buttonNum,
		Action: action,
		Shift:  shift,
		Alt:    alt,
		Ctrl:   ctrl,
	}
}

// parseInts parses semicolon-separated integers
func parseInts(s string, vals ...*int) (int, error) {
	count := 0
	start := 0
	valIndex := 0

	for i := 0; i <= len(s) && valIndex < len(vals); i++ {
		if i == len(s) || s[i] == ';' {
			if i > start {
				num := 0

				for j := start; j < i; j++ {
					if s[j] < '0' || s[j] > '9' {
						return count, nil
					}

					num = num*10 + int(s[j]-'0')
				}

				*vals[valIndex] = num
				count++
			}

			valIndex++
			start = i + 1
		}
	}
	return count, nil
}

//export tea_parse_input
func tea_parse_input(data *C.char, dataLength C.int) *C.char {
	if dataLength <= 0 {
		return C.CString("")
	}

	goData := C.GoBytes(unsafe.Pointer(data), dataLength)

	_, jsonEvent := ParseInput(goData)
	return C.CString(jsonEvent)
}

//export tea_parse_input_with_consumed
func tea_parse_input_with_consumed(data *C.char, dataLength C.int, consumed *C.int) *C.char {
	if dataLength <= 0 {
		*consumed = 0
		return C.CString("")
	}

	goData := C.GoBytes(unsafe.Pointer(data), dataLength)

	bytesConsumed, jsonEvent := ParseInput(goData)
	*consumed = C.int(bytesConsumed)
	return C.CString(jsonEvent)
}

//export tea_get_key_name
func tea_get_key_name(keyType C.int) *C.char {
	name, exists := keyNames[KeyType(keyType)]

	if !exists {
		return C.CString("")
	}

	return C.CString(name)
}
