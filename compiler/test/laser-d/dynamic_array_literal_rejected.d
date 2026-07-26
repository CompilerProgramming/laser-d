// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/dynamic_array_literal_rejected.d(13): Error: dynamic array literals are not supported in Laser-D
laser-d/dynamic_array_literal_rejected.d(18): Error: dynamic array literals are not supported in Laser-D
---
*/

void materializeLiteral()
{
    auto values = [1, 2, 3];
}

void initializeSlice()
{
    int[] values = [4, 5, 6];
}
