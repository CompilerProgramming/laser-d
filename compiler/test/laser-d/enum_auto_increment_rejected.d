// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/enum_auto_increment_rejected.d(19): Error: cannot automatically assign value to enum member `enum_auto_increment_rejected.Derived.second` because base type `Base` is an enum; provide an explicit value
---
*/

enum Base : int
{
    zero,
    one,
}

enum Derived : Base
{
    first = Base.zero,
    second,
}
