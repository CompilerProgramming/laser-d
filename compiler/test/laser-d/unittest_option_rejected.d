// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -unittest

/*
TEST_OUTPUT:
---
Error: `-unittest` is not supported in Laser-D; use explicit test programs
---
*/

int libraryFunction()
{
    return 42;
}
