// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/betterc_mandatory.d(13): Error: cannot use `throw` statements with `-betterC`
---
*/

// No -betterC argument is supplied: BetterC restrictions are mandatory.
void forbidden()
{
    throw new Exception("requires the D runtime");
}
