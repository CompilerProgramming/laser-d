// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/bitfield_non_integral_rejected.d(12): Error: bitfield `value` cannot be of non-integral type `float`
---
*/

struct Invalid
{
    float value : 3;
}
