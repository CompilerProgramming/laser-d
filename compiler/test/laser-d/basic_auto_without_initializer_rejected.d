// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/basic_auto_without_initializer_rejected.d(10): Error: variable name expected after type `missingInitializer`, not `;`
---
*/

auto missingInitializer;
