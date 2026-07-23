// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/runtime_assertions_rejected.d(15): Error: runtime `assert` expressions are not supported in Laser-D; use explicit error handling or `static assert` for compile-time checks
laser-d/runtime_assertions_rejected.d(20): Error: runtime `assert` expressions are not supported in Laser-D; use explicit error handling or `static assert` for compile-time checks
laser-d/runtime_assertions_rejected.d(25): Error: runtime `assert` expressions are not supported in Laser-D; use explicit error handling or `static assert` for compile-time checks
laser-d/runtime_assertions_rejected.d(30): Error: runtime `assert` expressions are not supported in Laser-D; use explicit error handling or `static assert` for compile-time checks
---
*/

void conditionOnly(int value)
{
    assert(value > 0);
}

void withMessage(int value)
{
    assert(value > 0, "value must be positive");
}

void unconditionalHalt()
{
    assert(0);
}

int compileTimeFunction(int value)
{
    assert(value > 0);
    return value;
}

enum compileTimeValue = compileTimeFunction(1);
