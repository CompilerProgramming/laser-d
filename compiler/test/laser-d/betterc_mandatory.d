// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/betterc_mandatory.d(13): Error: `throw` is not supported in Laser-D because D exception handling is disabled
---
*/

// No -betterC argument is supplied: BetterC restrictions are mandatory.
void forbidden()
{
    throw new Exception("requires the D runtime");
}
