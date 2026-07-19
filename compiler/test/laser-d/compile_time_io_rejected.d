// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/compile_time_io_rejected.d(11): Error: `pragma(msg)` is not supported in Laser-D because compile-time output is disabled
laser-d/compile_time_io_rejected.d(13): Error: import expressions are not supported in Laser-D because compile-time file I/O is disabled
---
*/

pragma(msg, "compile-time declaration output");

enum fileContents = import("compile_time_input.txt");
