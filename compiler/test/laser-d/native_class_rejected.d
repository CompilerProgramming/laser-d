// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/native_class_rejected.d(14): Error: native D class declarations are not supported in Laser-D
laser-d/native_class_rejected.d(16): Error: native D class declarations are not supported in Laser-D
laser-d/native_class_rejected.d(18): Error: native D class declarations are not supported in Laser-D
laser-d/native_class_rejected.d(22): Error: native D class declarations are not supported in Laser-D
laser-d/native_class_rejected.d(25): Error: native D class declarations are not supported in Laser-D
---
*/

class Forward;

class Defined { }

class Generic(T) { }

struct Outer
{
    class Nested { }
}

extern(D) class ExplicitD { }
