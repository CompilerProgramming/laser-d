// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/native_interface_rejected.d(14): Error: native D interface declarations are not supported in Laser-D
laser-d/native_interface_rejected.d(16): Error: native D interface declarations are not supported in Laser-D
laser-d/native_interface_rejected.d(18): Error: native D interface declarations are not supported in Laser-D
laser-d/native_interface_rejected.d(22): Error: native D interface declarations are not supported in Laser-D
laser-d/native_interface_rejected.d(25): Error: native D interface declarations are not supported in Laser-D
---
*/

interface Forward;

interface Defined { }

interface Generic(T) { }

struct Outer
{
    interface Nested { }
}

extern(D) interface ExplicitD { }
