#include "extension.h"

VALUE mBubbletea;
VALUE cProgram;

static VALUE bubbletea_upstream_version_rb(VALUE self) {
  char *version = tea_upstream_version();
  VALUE rb_version = rb_utf8_str_new_cstr(version);

  tea_free(version);

  return rb_version;
}

static VALUE bubbletea_version_rb(VALUE self) {
  VALUE gem_version = rb_const_get(self, rb_intern("VERSION"));
  VALUE upstream_version = bubbletea_upstream_version_rb(self);
  VALUE format_string = rb_utf8_str_new_cstr("bubbletea v%s (upstream charmbracelet/x/ansi %s) [Go native extension]");

  return rb_funcall(rb_mKernel, rb_intern("sprintf"), 3, format_string, gem_version, upstream_version);
}

static VALUE bubbletea_is_tty_rb(VALUE self) {
  return tea_terminal_is_tty() ? Qtrue : Qfalse;
}

static VALUE bubbletea_clear_screen_rb(VALUE self) {
  tea_terminal_clear_screen();
  return Qnil;
}

static VALUE bubbletea_set_window_title_rb(VALUE self, VALUE title) {
  Check_Type(title, T_STRING);
  tea_terminal_set_window_title(StringValueCStr(title));
  return Qnil;
}

static VALUE bubbletea_get_key_name_rb(VALUE self, VALUE key_type) {
  Check_Type(key_type, T_FIXNUM);
  char *name = tea_get_key_name(FIX2INT(key_type));
  VALUE rb_name = rb_utf8_str_new_cstr(name);
  free(name);
  return rb_name;
}

__attribute__((__visibility__("default"))) void Init_bubbletea(void) {
  rb_require("json");

  mBubbletea = rb_define_module("Bubbletea");

  Init_bubbletea_program();

  rb_define_singleton_method(mBubbletea, "upstream_version", bubbletea_upstream_version_rb, 0);
  rb_define_singleton_method(mBubbletea, "version", bubbletea_version_rb, 0);
  rb_define_singleton_method(mBubbletea, "tty?", bubbletea_is_tty_rb, 0);
  rb_define_singleton_method(mBubbletea, "clear_screen", bubbletea_clear_screen_rb, 0);
  rb_define_singleton_method(mBubbletea, "_set_window_title", bubbletea_set_window_title_rb, 1);
  rb_define_singleton_method(mBubbletea, "get_key_name", bubbletea_get_key_name_rb, 1);
}
