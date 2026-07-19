// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/explicit_function_type_attributes.d(13): Error: attribute `nothrow` is implicit in Laser-D and cannot be specified
laser-d/explicit_function_type_attributes.d(14): Error: attribute `@nogc` is implicit in Laser-D and cannot be specified
laser-d/explicit_function_type_attributes.d(16): Error: attribute `nothrow` is implicit in Laser-D and cannot be specified
laser-d/explicit_function_type_attributes.d(17): Error: attribute `@nogc` is implicit in Laser-D and cannot be specified
---
*/

alias ExplicitNothrowPointer = void function() nothrow;
alias ExplicitNogcPointer = void function() @nogc;

alias ExplicitNothrowDelegate = void delegate() nothrow;
alias ExplicitNogcDelegate = void delegate() @nogc;
