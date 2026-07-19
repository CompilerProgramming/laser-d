/* TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_compgoto.i(105): Error: unary `&&` computed goto extension is not supported
laser-d/importc_upstream_fail_compilation_compgoto.i(106): Error: `goto *` computed goto extension is not supported
---
 */

// https://gcc.gnu.org/onlinedocs/gcc/Labels-as-Values.html

#line 100

void test()
{
    void *ptr;
  foo:
    ptr = &&foo;
    goto *ptr;
}
// TEST_MODE: fail_compilation
