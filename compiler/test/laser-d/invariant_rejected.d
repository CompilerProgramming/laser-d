// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/invariant_rejected.d(14): Error: invariant declarations are not supported in Laser-D
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
