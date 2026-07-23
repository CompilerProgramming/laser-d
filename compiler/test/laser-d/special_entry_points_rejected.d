// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/special_entry_points_rejected.d(11): Error: `WinMain` entry points are not supported in Laser-D; use `extern(C) int main`
laser-d/special_entry_points_rejected.d(16): Error: `DllMain` entry points are not supported in Laser-D; use `extern(C) int main`
---
*/

int WinMain()
{
    return 0;
}

int DllMain()
{
    return 0;
}
