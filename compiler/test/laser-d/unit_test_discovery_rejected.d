// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/unit_test_discovery_rejected.d(12): Error: `__traits(getUnitTests)` is not supported in Laser-D because language unit-test blocks are disabled
---
*/

module unit_test_discovery_rejected;

alias tests = __traits(getUnitTests, unit_test_discovery_rejected);
