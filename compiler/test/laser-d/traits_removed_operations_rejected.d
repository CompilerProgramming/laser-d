// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/traits_removed_operations_rejected.d(11): Error: `__traits(toType)` is not supported in Laser-D because string-based type generation is disabled
laser-d/traits_removed_operations_rejected.d(12): Error: `__traits(getPointerBitmap)` is not supported in Laser-D because GC metadata is disabled
---
*/

alias GeneratedType = __traits(toType, "int");
enum pointerBitmap = __traits(getPointerBitmap, int*);
