package main

import "testing"

func TestParseMouseSGR(t *testing.T) {
	tests := []struct {
		name           string
		input          string
		x, y           int
		button, action int
	}{
		{"left press", "\x1b[<0;10;5M", 9, 4, 1, 0},
		{"middle press", "\x1b[<1;10;5M", 9, 4, 2, 0},
		{"right press", "\x1b[<2;10;5M", 9, 4, 3, 0},
		{"left release", "\x1b[<0;10;5m", 9, 4, 1, 1},
		{"left drag", "\x1b[<32;12;5M", 11, 4, 1, 2},
		{"motion without a button", "\x1b[<35;20;8M", 19, 7, 0, 2},
		{"wheel up", "\x1b[<64;1;1M", 0, 0, 4, 0},
		{"wheel down", "\x1b[<65;1;1M", 0, 0, 5, 0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			consumed, event := parseMouseSGR([]byte(tt.input))

			if consumed != len(tt.input) {
				t.Fatalf("consumed %d bytes, want %d", consumed, len(tt.input))
			}

			if event.X != tt.x || event.Y != tt.y || event.Button != tt.button || event.Action != tt.action {
				t.Errorf("got x=%d y=%d button=%d action=%d, want x=%d y=%d button=%d action=%d",
					event.X, event.Y, event.Button, event.Action, tt.x, tt.y, tt.button, tt.action)
			}
		})
	}
}
