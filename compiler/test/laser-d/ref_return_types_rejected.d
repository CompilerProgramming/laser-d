// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/ref_return_types_rejected.d(11): Error: `ref` return values are not supported in Laser-D
laser-d/ref_return_types_rejected.d(12): Error: `ref` return values are not supported in Laser-D
---
*/

alias RefFunction = ref int function();
alias RefDelegate = ref int delegate();
