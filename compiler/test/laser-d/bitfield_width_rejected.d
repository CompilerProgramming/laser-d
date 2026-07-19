// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/bitfield_width_rejected.d(12): Error: width `9` of bitfield `value` does not fit in type `ubyte`
---
*/

struct Invalid
{
    ubyte value : 9;
}
