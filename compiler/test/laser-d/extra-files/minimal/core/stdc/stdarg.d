// Minimal target ABI declarations for standalone Laser-D frontend tests.
module core.stdc.stdarg;

version (X86_64)
{
    version (Windows)
    {
        alias va_list = char*;
    }
    else
    {
        // Layout required by the x86-64 System V ABI.
        struct __va_list_tag
        {
            uint offset_regs;
            uint offset_fpregs;
            void* stack_args;
            void* reg_args;
        }

        alias __va_list = __va_list_tag;
        alias va_list = __va_list*;
    }
}
else
{
    alias va_list = char*;
}
