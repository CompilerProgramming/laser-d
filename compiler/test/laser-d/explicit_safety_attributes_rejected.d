// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/explicit_safety_attributes_rejected.d(15): Error: attribute `@safe` is not supported in Laser-D; all functions are implicitly `@system`
laser-d/explicit_safety_attributes_rejected.d(19): Error: attribute `@trusted` is not supported in Laser-D; all functions are implicitly `@system`
laser-d/explicit_safety_attributes_rejected.d(23): Error: attribute `@system` is not supported in Laser-D; all functions are implicitly `@system`
laser-d/explicit_safety_attributes_rejected.d(27): Error: attribute `@safe` is not supported in Laser-D; all functions are implicitly `@system`
laser-d/explicit_safety_attributes_rejected.d(28): Error: attribute `@trusted` is not supported in Laser-D; all functions are implicitly `@system`
laser-d/explicit_safety_attributes_rejected.d(29): Error: attribute `@system` is not supported in Laser-D; all functions are implicitly `@system`
---
*/

@safe void safeFunction()
{
}

void trustedFunction() @trusted
{
}

@system void systemFunction()
{
}

alias SafeFunction = void function() @safe;
alias TrustedFunction = void function() @trusted;
alias SystemFunction = void function() @system;
