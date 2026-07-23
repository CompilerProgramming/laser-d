// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/unittest_blocks_rejected.d(17): Error: `unittest` blocks are not supported in Laser-D; use explicit test functions and an explicit C entry point
laser-d/unittest_blocks_rejected.d(26): Error: `unittest` blocks are not supported in Laser-D; use explicit test functions and an explicit C entry point
laser-d/unittest_blocks_rejected.d(36): Error: `unittest` blocks are not supported in Laser-D; use explicit test functions and an explicit C entry point
---
*/

int add(int left, int right)
{
    return left + right;
}

unittest
{
    assert(add(20, 22) == 42);
}

struct Value
{
    int value;

    unittest
    {
        assert(Value(42).value == 42);
    }
}

template Identity(T)
{
    alias Identity = T;

    unittest
    {
        static assert(is(Identity!int == int));
    }
}
