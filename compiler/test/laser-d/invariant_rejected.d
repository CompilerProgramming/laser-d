// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/invariant_rejected.d(15): Error: invariant declarations are not supported in Laser-D
laser-d/invariant_rejected.d(17): Error: runtime `assert` expressions are not supported in Laser-D; use explicit error handling or `static assert` for compile-time checks
---
*/

struct Value
{
    int member;

    invariant
    {
        assert(member >= 0);
    }
}
