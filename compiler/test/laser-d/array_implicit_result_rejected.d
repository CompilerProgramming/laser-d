// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/array_implicit_result_rejected.d(12): Error: array operation `left[] + right[]` without destination memory not allowed
---
*/

int[] add(int[] left, int[] right)
{
    return left[] + right[];
}
