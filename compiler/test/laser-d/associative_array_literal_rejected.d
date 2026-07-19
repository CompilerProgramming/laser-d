// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/associative_array_literal_rejected.d(12): Error: associative array literals are not supported in Laser-D
---
*/

extern(C) int main()
{
    auto lookup = [1: 10, 2: 20];
    return lookup[1];
}
