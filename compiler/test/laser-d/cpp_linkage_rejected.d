// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/cpp_linkage_rejected.d(14): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_linkage_rejected.d(21): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_linkage_rejected.d(23): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_linkage_rejected.d(25): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
laser-d/cpp_linkage_rejected.d(27): Error: C++ linkage is not supported in Laser-D; expose a C ABI instead
---
*/

extern(C++)
{
    int cppFunction(int value);
    void overloaded(int value);
    void overloaded(double value);
}

alias FunctionType = extern(C++) int function(int);

extern(C++, namespace_name) int namespaced(int value);

extern(C++, class) struct ClassMangled;

extern(C++, struct) class StructMangled;
