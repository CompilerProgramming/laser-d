// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/gshared_rejected.d(10): Error: `__gshared` is not supported in Laser-D because D-owned shared global storage is disabled
---
*/

__gshared int globalValue;
