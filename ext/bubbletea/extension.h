#ifndef BUBBLETEA_EXTENSION_H
#define BUBBLETEA_EXTENSION_H

#include <ruby.h>
#include "libbubbletea.h"

extern VALUE mBubbletea;
extern VALUE cProgram;

extern const rb_data_type_t program_type;

typedef struct {
  unsigned long long handle;
  char pending_buf[256];  /* buffered bytes not yet consumed by poll_event */
  int  pending_len;       /* number of valid bytes in pending_buf */
} bubbletea_program_t;

#define GET_PROGRAM(self, program) \
  bubbletea_program_t *program; \
  TypedData_Get_Struct(self, bubbletea_program_t, &program_type, program)

void Init_bubbletea_program(void);

#endif
