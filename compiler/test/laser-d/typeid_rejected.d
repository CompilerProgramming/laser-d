// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/typeid_rejected.d(11): Error: `typeid` is not supported in Laser-D because runtime `TypeInfo` is disabled
laser-d/typeid_rejected.d(14): Error: `typeid` is not supported in Laser-D because runtime `TypeInfo` is disabled
---
*/

enum typeMetadata = typeid(int);

int value;
enum expressionMetadata = typeid(value);
