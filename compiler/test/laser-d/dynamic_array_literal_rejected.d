// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/dynamic_array_literal_rejected.d(12): Error: dynamic array literals are not supported in Laser-D
---
*/

void materializeLiteral()
{
    auto values = [1, 2, 3];
}
