// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/noreturn_main_rejected.d(12): Error: Laser-D entry point must be `extern(C) int main()` or `extern(C) int main(int, char**)`
---
*/

alias noreturn = typeof(*null);

extern(C) noreturn main()
{
    for (;;)
    {
    }
}
