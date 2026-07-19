// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/module_user_defined_attribute_rejected.d(10): Error: user-defined attributes are not supported in Laser-D
---
*/

@("module metadata") module module_user_defined_attribute_rejected;
