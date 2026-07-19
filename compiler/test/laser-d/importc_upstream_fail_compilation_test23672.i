/*
TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_test23672.i(10): Error: found `End of File` when expecting `)`
laser-d/importc_upstream_fail_compilation_test23672.i(10): Error: `=`, `;` or `,` expected to end declaration instead of `End of File`
---
*/
extern int feof (FILE *__strea
// TEST_MODE: fail_compilation
