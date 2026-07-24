// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -m32mscoff

/*
TEST_OUTPUT:
---
Error: `-m32mscoff` is not supported in Laser-D; target x86-64 with `-m64`
---
*/

int libraryFunction()
{
    return 42;
}
