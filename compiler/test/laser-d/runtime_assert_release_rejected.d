// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -release

/*
TEST_OUTPUT:
---
laser-d/runtime_assert_release_rejected.d(13): Error: runtime `assert` expressions are not supported in Laser-D; use explicit error handling or `static assert` for compile-time checks
---
*/

void validate(int value)
{
    assert(value > 0);
}
