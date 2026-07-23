// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -main

/*
TEST_OUTPUT:
---
Error: `-main` is not supported in Laser-D; define an explicit `extern(C) int main` entry point
---
*/

int libraryFunction()
{
    return 42;
}
