// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/union_overlapping_initializers_rejected.d(10): Error: overlapping default initialization for field `second` and `first`
---
*/

union Invalid
{
    int first = 1;
    int second = 2;
}
