package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"runtime/debug"
	"sync"
	"unsafe"
)

var (
	nextID   uint64 = 1
	nextIDMu sync.Mutex
)

func getNextID() uint64 {
	nextIDMu.Lock()
	defer nextIDMu.Unlock()
	id := nextID
	nextID++
	return id
}

var (
	programs   = make(map[uint64]*ProgramState)
	programsMu sync.RWMutex
)

type ProgramState struct {
	terminal *Terminal
	input    *InputReader
	width    int
	height   int
}

func getProgram(id uint64) *ProgramState {
	programsMu.RLock()
	defer programsMu.RUnlock()
	return programs[id]
}

//export tea_free
func tea_free(pointer *C.char) {
	C.free(unsafe.Pointer(pointer))
}

//export tea_new_program
func tea_new_program() C.ulonglong {
	state := &ProgramState{}

	programsMu.Lock()
	id := getNextID()
	programs[id] = state
	programsMu.Unlock()

	return C.ulonglong(id)
}

//export tea_free_program
func tea_free_program(id C.ulonglong) {
	programsMu.Lock()
	defer programsMu.Unlock()

	state := programs[uint64(id)]
	if state != nil {
		if state.input != nil {
			state.input.Stop()
		}

		if state.terminal != nil {
			state.terminal.Restore()
		}
	}

	delete(programs, uint64(id))
}

//export tea_upstream_version
func tea_upstream_version() *C.char {
	info, ok := debug.ReadBuildInfo()

	if !ok {
		return C.CString("unknown")
	}

	for _, dep := range info.Deps {
		if dep.Path == "github.com/charmbracelet/x/ansi" {
			return C.CString(dep.Version)
		}
	}

	return C.CString("unknown")
}

func main() {}
