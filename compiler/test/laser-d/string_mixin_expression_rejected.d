// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/string_mixin_expression_rejected.d(10): Error: string mixin expressions are not supported in Laser-D
---
*/

enum value = mixin("1 + 2");
