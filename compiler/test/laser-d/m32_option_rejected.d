// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -m32

/*
TEST_OUTPUT:
---
Error: `-m32` is not supported in Laser-D; target x86-64 with `-m64`
---
*/

int libraryFunction()
{
    return 42;
}
