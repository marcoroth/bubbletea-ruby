#ifndef BUBBLETEA_EXTENSION_H
#define BUBBLETEA_EXTENSION_H

#include <ruby.h>
#include "libbubbletea.h"

extern VALUE mBubbletea;
extern VALUE cProgram;

extern const rb_data_type_t program_type;

#define BUBBLETEA_INPUT_BUFFER_SIZE 256

typedef struct {
  unsigned long long handle;
  char input[BUBBLETEA_INPUT_BUFFER_SIZE];
  int input_length;
} bubbletea_program_t;

#define GET_PROGRAM(self, program) \
  bubbletea_program_t *program; \
  TypedData_Get_Struct(self, bubbletea_program_t, &program_type, program)

void Init_bubbletea_program(void);

#endif
