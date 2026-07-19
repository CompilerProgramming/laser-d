// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/explicit_function_attributes.d(11): Error: attribute `nothrow` is implicit in Laser-D and cannot be specified
laser-d/explicit_function_attributes.d(15): Error: attribute `@nogc` is implicit in Laser-D and cannot be specified
---
*/

void explicitNothrow() nothrow
{
}

void explicitNogc() @nogc
{
}
