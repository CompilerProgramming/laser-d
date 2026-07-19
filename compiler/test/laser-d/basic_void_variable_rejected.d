// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/basic_void_variable_rejected.d(12): Error: variable `basic_void_variable_rejected.inspect.noValue` - variables cannot be of type `void`
---
*/

void inspect()
{
    void noValue;
}
