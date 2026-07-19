// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/native_anonymous_class_rejected.d(14): Error: native D class declarations are not supported in Laser-D
---
*/

extern(C) void consume(void*);

void createAnonymous()
{
    auto value = new class { };
    consume(cast(void*) value);
}
