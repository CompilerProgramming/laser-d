// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/compile_time_statement_output_rejected.d(12): Error: `pragma(msg)` is not supported in Laser-D because compile-time output is disabled
---
*/

void inspect()
{
    pragma(msg, "compile-time statement output");
}
