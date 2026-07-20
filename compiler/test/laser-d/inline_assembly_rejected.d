// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/inline_assembly_rejected.d(13): Error: inline assembly is not supported in Laser-D
laser-d/inline_assembly_rejected.d(21): Error: inline assembly is not supported in Laser-D
---
*/

void dStyleAssembly()
{
    asm
    {
        nop;
    }
}

void extendedAssembly()
{
    asm
    {
        "nop";
    }
}
