// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/string_mixin_declaration_rejected.d(10): Error: string mixin declarations are not supported in Laser-D
---
*/

mixin("int generated;");
