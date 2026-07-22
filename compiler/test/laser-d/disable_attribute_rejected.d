// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/disable_attribute_rejected.d(10): Error: attribute `@disable` is not supported in Laser-D
---
*/

@disable void unavailable();
