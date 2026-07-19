/*
TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_fail21740c.i(9): Error: character '\' is not a valid token
laser-d/importc_upstream_fail_compilation_fail21740c.i(10): Error: character '\' is not a valid token
laser-d/importc_upstream_fail_compilation_fail21740c.i(10): Error: missing comma or semicolon after declaration of `é`, found `q` instead
---
*/
int \uq;
int \u00e9\q;
// TEST_MODE: fail_compilation
