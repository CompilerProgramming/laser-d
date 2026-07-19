/*
TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_fail21740a.i(7): Error: `=`, `;` or `,` expected to end declaration instead of `)`
---
*/
int a\U000000aa);
// TEST_MODE: fail_compilation
