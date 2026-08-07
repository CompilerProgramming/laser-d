// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/private_local_declaration_rejected.d(14): Error: found `private` instead of statement
---
*/

module private_local_declaration_rejected;

int functionWithPrivateLocal()
{
    private int value;
    return value;
}
