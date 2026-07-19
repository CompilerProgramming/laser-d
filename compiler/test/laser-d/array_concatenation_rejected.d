// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/array_concatenation_rejected.d(14): Error: array concatenation is not supported in Laser-D
laser-d/array_concatenation_rejected.d(19): Error: array append is not supported in Laser-D
laser-d/array_concatenation_rejected.d(24): Error: array append is not supported in Laser-D
---
*/

void concatenate(int[] left, int[] right)
{
    auto result = left ~ right;
}

void appendArray(int[] destination, int[] source)
{
    destination ~= source;
}

void appendElement(int[] destination)
{
    destination ~= 1;
}
