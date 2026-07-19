// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/string_mixin_statement_rejected.d(12): Error: string mixin statements are not supported in Laser-D
---
*/

void generateStatement()
{
    mixin("int local;");
}
