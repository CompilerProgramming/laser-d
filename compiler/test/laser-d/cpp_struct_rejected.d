// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/cpp_struct_rejected.d(13): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_struct_rejected.d(15): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_struct_rejected.d(17): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_struct_rejected.d(19): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
---
*/

extern(C++) struct Forward;

extern(C++) struct Defined { }

extern(C++) struct Generic(T) { }

extern(C++, class) struct ClassMangled { }
