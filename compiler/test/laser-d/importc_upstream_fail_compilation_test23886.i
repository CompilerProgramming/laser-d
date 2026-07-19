/* TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_test23886.i(103): Error: "string" expected after `#ident`
laser-d/importc_upstream_fail_compilation_test23886.i(103): Error: no type for declarator before `#`
laser-d/importc_upstream_fail_compilation_test23886.i(104): Error: "string" expected after `#ident`
laser-d/importc_upstream_fail_compilation_test23886.i(105): Error: "string" expected after `#ident`
---
*/

// https://issues.dlang.org/show_bug.cgi?id=23886

#line 100

#ident "abc"

#ident 7
#ident "def" x
#ident

void test() { }
// TEST_MODE: fail_compilation
