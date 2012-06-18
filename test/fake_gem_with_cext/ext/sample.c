static VALUE unlink(VALUE self)
{
  return 1;
}

void init_sample(void)
{
  VALUE klass = rb_define_class("Sample", rb_cObject);
  rb_define_method(klass, "unlink", unlink, 0);
}


