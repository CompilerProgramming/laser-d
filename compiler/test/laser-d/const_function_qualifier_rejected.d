// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/const_function_qualifier_rejected.d(14): Error: `const` function qualifiers are not supported in Laser-D; use `immutable` for a permanently unmodifiable receiver
---
*/

struct Value
{
    int number;

    int read() const
    {
        return number;
    }
}
