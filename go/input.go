package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"context"
	"os"
	"sync"
	"time"
	"unsafe"
	"github.com/muesli/cancelreader"
)

type InputReader struct {
	cancelReader cancelreader.CancelReader
	ctx          context.Context
	cancel       context.CancelFunc
	events       chan []byte
	mu           sync.Mutex
	running      bool
}

func NewInputReader() (*InputReader, error) {
	reader, err := cancelreader.NewReader(os.Stdin)

	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithCancel(context.Background())

	return &InputReader{
		cancelReader: reader,
		ctx:          ctx,
		cancel:       cancel,
		events:       make(chan []byte, 100),
	}, nil
}

func (reader *InputReader) Start() {
	reader.mu.Lock()

	if reader.running {
		reader.mu.Unlock()
		return
	}

	reader.running = true
	reader.mu.Unlock()

	go reader.readLoop()
}

func (reader *InputReader) Stop() {
	reader.mu.Lock()
	defer reader.mu.Unlock()

	if !reader.running {
		return
	}

	reader.running = false
	reader.cancel()
	reader.cancelReader.Cancel()
	reader.cancelReader.Close()
}

func (reader *InputReader) readLoop() {
	var buf [256]byte

	for {
		select {
		case <-reader.ctx.Done():
			return
		default:
		}

		n, err := reader.cancelReader.Read(buf[:])
		if err != nil {
			return
		}

		if n > 0 {
			data := make([]byte, n)
			copy(data, buf[:n])

			select {
			case reader.events <- data:
			case <-reader.ctx.Done():
				return
			}
		}
	}
}

//export tea_input_start_reader
func tea_input_start_reader(programID C.ulonglong) C.int {
	state := getProgram(uint64(programID))
	if state == nil {
		return -1
	}

	if state.input != nil {
		return 0
	}

	reader, err := NewInputReader()
	if err != nil {
		return -1
	}

	state.input = reader
	reader.Start()

	return 0
}

//export tea_input_stop_reader
func tea_input_stop_reader(programID C.ulonglong) {
	state := getProgram(uint64(programID))
	if state == nil || state.input == nil {
		return
	}

	state.input.Stop()
	state.input = nil
}

//export tea_input_read_raw
func tea_input_read_raw(programID C.ulonglong, buffer *C.char, bufferSize C.int, timeoutMs C.int) C.int {
	state := getProgram(uint64(programID))

	if state == nil || state.input == nil {
		return -1
	}

	timeout := time.Duration(timeoutMs) * time.Millisecond

	select {
	case data := <-state.input.events:
		copyLength := len(data)

		if copyLength > int(bufferSize) {
			copyLength = int(bufferSize)
		}

		cBuffer := (*[1 << 20]byte)(unsafe.Pointer(buffer))[:copyLength:copyLength]
		copy(cBuffer, data[:copyLength])

		return C.int(copyLength)

	case <-time.After(timeout):
		return 0
	}
}
