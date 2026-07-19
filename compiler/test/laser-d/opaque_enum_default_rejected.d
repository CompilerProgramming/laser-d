// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/opaque_enum_default_rejected.d(14): Error: enum `opaque_enum_default_rejected.Opaque` is opaque and has no default initializer
---
*/

enum Opaque : int;

void construct()
{
    Opaque value;
}
