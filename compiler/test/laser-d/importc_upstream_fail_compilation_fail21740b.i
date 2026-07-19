/*
TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_fail21740b.i(7): Error: undefined identifier `é`
---
*/
void *p = &\u00e9;
// TEST_MODE: fail_compilation
