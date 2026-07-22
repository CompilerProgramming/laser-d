// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/ref_constructor_rejected.d(12): Error: `ref` return values are not supported in Laser-D
---
*/

struct Invalid
{
    ref this(int value)
    {
    }
}
