// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/const_rejected.d(12): Error: `const` is not supported in Laser-D; use `immutable` for permanently unmodifiable data
laser-d/const_rejected.d(13): Error: `const` is not supported in Laser-D; use `immutable` for permanently unmodifiable data
laser-d/const_rejected.d(18): Error: `const` is not supported in Laser-D; use `immutable` for permanently unmodifiable data
---
*/

alias ReadOnlyInteger = const(int);
const int moduleValue = 1;

struct Value
{
    int number;
    int read() const
    {
        return number;
    }
}
