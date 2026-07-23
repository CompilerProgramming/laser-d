/**
 * C variadic ABI types supported by Laser-D.
 *
 * Derived from druntime's core.stdc.stdarg and
 * core.internal.vararg.sysv_x64.
 */
module core.stdc.stdarg;

version (X86_64)
{
    version (Windows)
    {
        alias va_list = char*;
    }
    else
    {
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
