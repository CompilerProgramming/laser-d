// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/string_mixin_type_rejected.d(10): Error: string mixin types are not supported in Laser-D
---
*/

mixin("int") value;
