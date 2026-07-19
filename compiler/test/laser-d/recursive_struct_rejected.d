// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/recursive_struct_rejected.d(12): Error: struct `recursive_struct_rejected.Recursive` cannot have field `value` with same struct type
---
*/

struct Recursive
{
    Recursive value;
}
