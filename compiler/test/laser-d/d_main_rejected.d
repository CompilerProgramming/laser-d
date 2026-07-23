// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/d_main_rejected.d(10): Error: Laser-D entry point must be `extern(C) int main()` or `extern(C) int main(int, char**)`
---
*/

int main()
{
    return 0;
}
