// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/new_array_rejected.d(12): Error: dynamic array allocation with `new` is not supported in Laser-D
---
*/

extern(C) int main()
{
    auto values = new int[4];
    return values.length;
}
