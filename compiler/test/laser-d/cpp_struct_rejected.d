// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/cpp_struct_rejected.d(13): Error: C++ struct declarations are not supported in Laser-D
laser-d/cpp_struct_rejected.d(15): Error: C++ struct declarations are not supported in Laser-D
laser-d/cpp_struct_rejected.d(17): Error: C++ struct declarations are not supported in Laser-D
laser-d/cpp_struct_rejected.d(19): Error: C++ struct declarations are not supported in Laser-D
---
*/

extern(C++) struct Forward;

extern(C++) struct Defined { }

extern(C++) struct Generic(T) { }

extern(C++, class) struct ClassMangled { }
