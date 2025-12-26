#include "extension.h"

static void program_free(void *pointer) {
  bubbletea_program_t *program = (bubbletea_program_t *)pointer;

  if (program->handle != 0) {
    tea_free_program(program->handle);
  }

  xfree(program);
}

static size_t program_memsize(const void *pointer) {
  return sizeof(bubbletea_program_t);
}

const rb_data_type_t program_type = {
  .wrap_struct_name = "Bubbletea::Program",
  .function = {
    .dmark = NULL,
    .dfree = program_free,
    .dsize = program_memsize,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE program_alloc(VALUE klass) {
  bubbletea_program_t *program = ALLOC(bubbletea_program_t);
  program->handle = tea_new_program();
  return TypedData_Wrap_Struct(klass, &program_type, program);
}

static VALUE program_initialize(VALUE self) {
  GET_PROGRAM(self, program);

  tea_terminal_init(program->handle);

  return self;
}

/* Terminal control methods */

static VALUE program_enter_raw_mode(VALUE self) {
  GET_PROGRAM(self, program);
  return tea_terminal_enter_raw_mode(program->handle) == 0 ? Qtrue : Qfalse;
}

static VALUE program_exit_raw_mode(VALUE self) {
  GET_PROGRAM(self, program);
  return tea_terminal_exit_raw_mode(program->handle) == 0 ? Qtrue : Qfalse;
}

static VALUE program_enter_alt_screen(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_enter_alt_screen(program->handle);
  return Qnil;
}

static VALUE program_exit_alt_screen(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_exit_alt_screen(program->handle);
  return Qnil;
}

static VALUE program_hide_cursor(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_hide_cursor(program->handle);
  return Qnil;
}

static VALUE program_show_cursor(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_show_cursor(program->handle);
  return Qnil;
}

static VALUE program_enable_mouse_cell_motion(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_enable_mouse_cell_motion(program->handle);
  return Qnil;
}

static VALUE program_enable_mouse_all_motion(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_enable_mouse_all_motion(program->handle);
  return Qnil;
}

static VALUE program_disable_mouse(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_disable_mouse(program->handle);
  return Qnil;
}

static VALUE program_enable_bracketed_paste(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_enable_bracketed_paste(program->handle);
  return Qnil;
}

static VALUE program_disable_bracketed_paste(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_disable_bracketed_paste(program->handle);
  return Qnil;
}

static VALUE program_enable_report_focus(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_enable_report_focus(program->handle);
  return Qnil;
}

static VALUE program_disable_report_focus(VALUE self) {
  GET_PROGRAM(self, program);
  tea_terminal_disable_report_focus(program->handle);
  return Qnil;
}

static VALUE program_terminal_size(VALUE self) {
  GET_PROGRAM(self, program);
  int width, height;

  if (tea_terminal_get_size(program->handle, &width, &height) == 0) {
    return rb_ary_new_from_args(2, INT2NUM(width), INT2NUM(height));
  }

  return Qnil;
}

/* Input methods */

static VALUE program_start_input_reader(VALUE self) {
  GET_PROGRAM(self, program);
  return tea_input_start_reader(program->handle) == 0 ? Qtrue : Qfalse;
}

static VALUE program_stop_input_reader(VALUE self) {
  GET_PROGRAM(self, program);
  tea_input_stop_reader(program->handle);
  return Qnil;
}

static VALUE program_read_raw_input(VALUE self, VALUE timeout_ms) {
  GET_PROGRAM(self, program);

  char buffer[256];
  int bytes_read = tea_input_read_raw(program->handle, buffer, sizeof(buffer), NUM2INT(timeout_ms));

  if (bytes_read > 0) {
    return rb_str_new(buffer, bytes_read);
  } else if (bytes_read == 0) {
    return Qnil; // Timeout
  } else {
    return Qnil; // Error
  }
}

static VALUE program_poll_event(VALUE self, VALUE timeout_ms) {
  GET_PROGRAM(self, program);

  char buffer[256];
  int bytes_read = tea_input_read_raw(program->handle, buffer, sizeof(buffer), NUM2INT(timeout_ms));

  if (bytes_read <= 0) {
    return Qnil; // Timeout or error
  }

  int consumed;
  char *json = tea_parse_input_with_consumed(buffer, bytes_read, &consumed);

  if (json == NULL || json[0] == '\0') {
    tea_free(json);
    return Qnil;
  }

  VALUE rb_json = rb_utf8_str_new_cstr(json);
  tea_free(json);

  VALUE rb_json_module = rb_const_get(rb_cObject, rb_intern("JSON"));
  VALUE rb_hash = rb_funcall(rb_json_module, rb_intern("parse"), 1, rb_json);

  return rb_hash;
}

/* Renderer methods */

static VALUE program_create_renderer(VALUE self) {
  GET_PROGRAM(self, program);
  unsigned long long renderer_id = tea_renderer_new(program->handle);
  return ULL2NUM(renderer_id);
}

static VALUE program_render(VALUE self, VALUE renderer_id, VALUE view) {
  Check_Type(view, T_STRING);
  tea_renderer_render(NUM2ULL(renderer_id), StringValueCStr(view));
  return Qnil;
}

static VALUE program_renderer_set_size(VALUE self, VALUE renderer_id, VALUE width, VALUE height) {
  tea_renderer_set_size(NUM2ULL(renderer_id), NUM2INT(width), NUM2INT(height));
  return Qnil;
}

static VALUE program_renderer_set_alt_screen(VALUE self, VALUE renderer_id, VALUE enabled) {
  tea_renderer_set_alt_screen(NUM2ULL(renderer_id), RTEST(enabled) ? 1 : 0);
  return Qnil;
}

static VALUE program_renderer_clear(VALUE self, VALUE renderer_id) {
  tea_renderer_clear(NUM2ULL(renderer_id));
  return Qnil;
}

static VALUE program_string_width(VALUE self, VALUE str) {
  Check_Type(str, T_STRING);
  return INT2NUM(tea_string_width(StringValueCStr(str)));
}

void Init_bubbletea_program(void) {
  cProgram = rb_define_class_under(mBubbletea, "Program", rb_cObject);

  rb_define_alloc_func(cProgram, program_alloc);
  rb_define_method(cProgram, "initialize", program_initialize, 0);

  rb_define_method(cProgram, "enter_raw_mode", program_enter_raw_mode, 0);
  rb_define_method(cProgram, "exit_raw_mode", program_exit_raw_mode, 0);
  rb_define_method(cProgram, "enter_alt_screen", program_enter_alt_screen, 0);
  rb_define_method(cProgram, "exit_alt_screen", program_exit_alt_screen, 0);
  rb_define_method(cProgram, "hide_cursor", program_hide_cursor, 0);
  rb_define_method(cProgram, "show_cursor", program_show_cursor, 0);
  rb_define_method(cProgram, "enable_mouse_cell_motion", program_enable_mouse_cell_motion, 0);
  rb_define_method(cProgram, "enable_mouse_all_motion", program_enable_mouse_all_motion, 0);
  rb_define_method(cProgram, "disable_mouse", program_disable_mouse, 0);
  rb_define_method(cProgram, "enable_bracketed_paste", program_enable_bracketed_paste, 0);
  rb_define_method(cProgram, "disable_bracketed_paste", program_disable_bracketed_paste, 0);
  rb_define_method(cProgram, "enable_report_focus", program_enable_report_focus, 0);
  rb_define_method(cProgram, "disable_report_focus", program_disable_report_focus, 0);
  rb_define_method(cProgram, "terminal_size", program_terminal_size, 0);

  rb_define_method(cProgram, "start_input_reader", program_start_input_reader, 0);
  rb_define_method(cProgram, "stop_input_reader", program_stop_input_reader, 0);
  rb_define_method(cProgram, "read_raw_input", program_read_raw_input, 1);
  rb_define_method(cProgram, "poll_event", program_poll_event, 1);

  rb_define_method(cProgram, "create_renderer", program_create_renderer, 0);
  rb_define_method(cProgram, "render", program_render, 2);
  rb_define_method(cProgram, "renderer_set_size", program_renderer_set_size, 3);
  rb_define_method(cProgram, "renderer_set_alt_screen", program_renderer_set_alt_screen, 2);
  rb_define_method(cProgram, "renderer_clear", program_renderer_clear, 1);
  rb_define_method(cProgram, "string_width", program_string_width, 1);
}
