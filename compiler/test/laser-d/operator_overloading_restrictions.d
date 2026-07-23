// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/operator_overloading_restrictions.d(15): Error: `ref` return values are not supported in Laser-D
laser-d/operator_overloading_restrictions.d(20): Error: `const` function qualifiers are not supported in Laser-D; use `immutable` for a permanently unmodifiable receiver
---
*/

struct Restricted
{
    int[1] storage;

    ref int opIndex(ulong index)
    {
        return storage[index];
    }

    bool opEquals(Restricted right) const
    {
        return true;
    }
}
