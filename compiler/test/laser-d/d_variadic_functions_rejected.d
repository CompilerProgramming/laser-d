// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/d_variadic_functions_rejected.d(13): Error: D-style variadic functions are not supported in Laser-D; use `extern(C)` variadics for C interoperability
laser-d/d_variadic_functions_rejected.d(15): Error: D-style variadic functions are not supported in Laser-D; use `extern(C)` variadics for C interoperability
laser-d/d_variadic_functions_rejected.d(17): Error: typesafe variadic functions are not supported in Laser-D; use variadic template parameters or an explicit aggregate
laser-d/d_variadic_functions_rejected.d(19): Error: typesafe variadic functions are not supported in Laser-D; use variadic template parameters or an explicit aggregate
---
*/

void untypedDeclaration(...);

alias DVariadicFunction = void function(int, ...);

void typesafeArray(int[] values...);

void typesafeFixedArray(int[2] values...);
