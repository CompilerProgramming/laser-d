// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/cpp_class_rejected.d(14): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_class_rejected.d(16): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_class_rejected.d(18): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_class_rejected.d(20): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_class_rejected.d(22): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
---
*/

extern(C++) class Forward;

extern(C++) class Defined { }

extern(C++) class Generic(T) { }

extern(C++, class) class ClassMangled { }

extern(C++, struct) class StructMangled { }
