// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/alias_this_rejected.d(14): Error: `alias this` declarations are not supported in Laser-D
laser-d/alias_this_rejected.d(20): Error: `alias this` declarations are not supported in Laser-D
---
*/

struct LegacySyntax
{
    int value;
    alias value this;
}

struct AssignmentSyntax
{
    int value;
    alias this = value;
}
