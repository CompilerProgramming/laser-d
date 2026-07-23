// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/posix_main_extension_rejected.d(10): Error: Laser-D entry point must be `extern(C) int main()` or `extern(C) int main(int, char**)`
---
*/

extern(C) int main(int argc, char** argv, char** environment)
{
    return 0;
}
