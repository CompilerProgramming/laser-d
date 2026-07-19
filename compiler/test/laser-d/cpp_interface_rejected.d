// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/cpp_interface_rejected.d(13): Error: C++ interface declarations are not supported in Laser-D
laser-d/cpp_interface_rejected.d(15): Error: C++ interface declarations are not supported in Laser-D
laser-d/cpp_interface_rejected.d(17): Error: C++ interface declarations are not supported in Laser-D
laser-d/cpp_interface_rejected.d(19): Error: C++ interface declarations are not supported in Laser-D
---
*/

extern(C++) interface Forward;

extern(C++) interface Defined { }

extern(C++) interface Generic(T) { }

extern(C++, class) interface ClassMangled { }
