// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/struct_postblit_rejected.d(13): Error: struct postblit constructors are not supported in Laser-D
---
*/

struct Copyable
{
    int value;
    this(this) { }
}
