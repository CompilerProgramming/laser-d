// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/associative_arrays_rejected.d(15): Error: associative array types are not supported in Laser-D
laser-d/associative_arrays_rejected.d(16): Error: associative array types are not supported in Laser-D
---
*/

alias Key = int;

void rejectAssociativeArrays()
{
    int[int] direct;
    int[Key] named;
}
