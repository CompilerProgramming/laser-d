// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/template_struct_constructor_issue.d(15): Error: `ref` return values are not supported in Laser-D
laser-d/template_struct_constructor_issue.d(21): Error: template instance `template_struct_constructor_issue.Box!int` error instantiating
---
*/

struct Box(T)
{
    T value;

    this(T initial)
    {
        value = initial;
    }
}

alias IntegerBox = Box!int;
