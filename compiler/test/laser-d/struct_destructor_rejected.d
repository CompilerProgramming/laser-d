// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/struct_destructor_rejected.d(13): Error: struct destructors are not supported in Laser-D
---
*/

struct Resource
{
    int value;
    ~this() { }
}
