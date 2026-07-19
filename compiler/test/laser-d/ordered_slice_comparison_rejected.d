// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/ordered_slice_comparison_rejected.d(12): Error: ordered array and slice comparisons are not supported in Laser-D
---
*/

bool ordered(immutable(char)[] left, immutable(char)[] right)
{
    return left < right;
}
