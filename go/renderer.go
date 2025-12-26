package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"os"
	"strings"
	"sync"
	"unsafe"
	"github.com/charmbracelet/x/ansi"
)

type Renderer struct {
	mu            sync.Mutex
	lastRender    string
	lastLines     []string
	linesRendered int
	width         int
	height        int
	altScreen     bool
	cursorHidden  bool
}

var (
	renderers   = make(map[uint64]*Renderer)
	renderersMu sync.RWMutex
)

func getRenderer(id uint64) *Renderer {
	renderersMu.RLock()
	defer renderersMu.RUnlock()
	return renderers[id]
}

//export tea_renderer_new
func tea_renderer_new(programID C.ulonglong) C.ulonglong {
	renderer := &Renderer{}

	renderersMu.Lock()
	id := getNextID()
	renderers[id] = renderer
	renderersMu.Unlock()

	state := getProgram(uint64(programID))

	if state != nil {
		state.width = 80
		state.height = 24
	}

	return C.ulonglong(id)
}

//export tea_renderer_free
func tea_renderer_free(id C.ulonglong) {
	renderersMu.Lock()
	delete(renderers, uint64(id))
	renderersMu.Unlock()
}

//export tea_renderer_set_size
func tea_renderer_set_size(id C.ulonglong, width C.int, height C.int) {
	renderer := getRenderer(uint64(id))

	if renderer == nil {
		return
	}

	renderer.mu.Lock()
	renderer.width = int(width)
	renderer.height = int(height)
	renderer.mu.Unlock()
}

//export tea_renderer_set_alt_screen
func tea_renderer_set_alt_screen(id C.ulonglong, enabled C.int) {
	renderer := getRenderer(uint64(id))
	if renderer == nil {
		return
	}

	renderer.mu.Lock()
	renderer.altScreen = enabled != 0
	renderer.mu.Unlock()
}

//export tea_renderer_render
func tea_renderer_render(id C.ulonglong, view *C.char) {
	renderer := getRenderer(uint64(id))

	if renderer == nil {
		return
	}

	renderer.mu.Lock()
	defer renderer.mu.Unlock()

	viewString := C.GoString(view)

	if viewString == renderer.lastRender {
		return
	}

	var buffer strings.Builder
	newLines := strings.Split(viewString, "\n")

	if renderer.height > 0 && len(newLines) > renderer.height {
		newLines = newLines[len(newLines)-renderer.height:]
	}

	if renderer.altScreen {
		buffer.WriteString(ansi.CursorHomePosition)

		for i, line := range newLines {
			if renderer.width > 0 && ansi.StringWidth(line) > renderer.width {
				line = ansi.Truncate(line, renderer.width, "")
			}

			buffer.WriteString(line)
			buffer.WriteString(ansi.EraseLine(0))

			if i < len(newLines) - 1 {
				buffer.WriteString("\r\n")
			}
		}

		if len(newLines) < renderer.linesRendered {
			for i := len(newLines); i < renderer.linesRendered; i++ {
				buffer.WriteString("\r\n")
				buffer.WriteString(ansi.EraseLine(2))
			}
		}
	} else {
		if renderer.linesRendered > 1 {
			buffer.WriteString(ansi.CursorUp(renderer.linesRendered - 1))
		}
		buffer.WriteString("\r")

		for i, line := range newLines {
			if renderer.width > 0 && ansi.StringWidth(line) > renderer.width {
				line = ansi.Truncate(line, renderer.width, "")
			}

			buffer.WriteString(line)
			buffer.WriteString(ansi.EraseLine(0))

			if i < len(newLines) - 1 {
				buffer.WriteString("\r\n")
			}
		}

		if len(newLines) < renderer.linesRendered {
			for i := len(newLines); i < renderer.linesRendered; i++ {
				buffer.WriteString("\r\n")
				buffer.WriteString(ansi.EraseLine(2))
			}

			buffer.WriteString(ansi.CursorUp(renderer.linesRendered - len(newLines)))
		}

		buffer.WriteString("\r")
	}

	os.Stdout.WriteString(buffer.String())

	renderer.lastRender = viewString
	renderer.lastLines = newLines
	renderer.linesRendered = len(newLines)
}

//export tea_renderer_clear
func tea_renderer_clear(id C.ulonglong) {
	renderer := getRenderer(uint64(id))

	if renderer == nil {
		return
	}

	renderer.mu.Lock()
	defer renderer.mu.Unlock()

	os.Stdout.WriteString(ansi.EraseEntireScreen)
	os.Stdout.WriteString(ansi.CursorHomePosition)

	renderer.lastRender = ""
	renderer.lastLines = nil
	renderer.linesRendered = 0
}

//export tea_string_width
func tea_string_width(s *C.char) C.int {
	return C.int(ansi.StringWidth(C.GoString(s)))
}

//export tea_truncate_string
func tea_truncate_string(s *C.char, width C.int) *C.char {
	result := ansi.Truncate(C.GoString(s), int(width), "")
	return C.CString(result)
}

var _ = unsafe.Pointer(nil)
