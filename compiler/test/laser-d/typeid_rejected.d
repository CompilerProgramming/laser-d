// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/typeid_rejected.d(10): Error: `typeid` is not supported in Laser-D because runtime `TypeInfo` is disabled
---
*/

enum typeMetadata = typeid(int);
