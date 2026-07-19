// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/template_string_mixin_rejected.d(12): Error: string mixin declarations are not supported in Laser-D
---
*/

template GeneratedDeclaration()
{
    mixin("int generated;");
}

alias Instance = GeneratedDeclaration!();
