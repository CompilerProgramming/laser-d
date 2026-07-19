// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/bitfield_named_zero_width_rejected.d(12): Error: bitfield `value` cannot have zero width
---
*/

struct Invalid
{
    uint value : 0;
}
