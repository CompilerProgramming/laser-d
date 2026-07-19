/* TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_test23715.i(11): Error: `_Thread_local` in block scope must be accompanied with `static` or `extern`
---
*/

// https://issues.dlang.org/show_bug.cgi?id=23715

void test2()
{
    _Thread_local int tli;
}
// TEST_MODE: fail_compilation
