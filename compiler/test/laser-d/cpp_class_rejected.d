// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/cpp_class_rejected.d(14): Error: C++ class declarations are not supported in Laser-D
laser-d/cpp_class_rejected.d(16): Error: C++ class declarations are not supported in Laser-D
laser-d/cpp_class_rejected.d(18): Error: C++ class declarations are not supported in Laser-D
laser-d/cpp_class_rejected.d(20): Error: C++ class declarations are not supported in Laser-D
laser-d/cpp_class_rejected.d(22): Error: C++ class declarations are not supported in Laser-D
---
*/

extern(C++) class Forward;

extern(C++) class Defined { }

extern(C++) class Generic(T) { }

extern(C++, class) class ClassMangled { }

extern(C++, struct) class StructMangled { }
