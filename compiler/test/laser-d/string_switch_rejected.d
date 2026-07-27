// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/string_switch_rejected.d(13): Error: string `switch` statements are not supported in Laser-D because they require the D runtime
---
*/

extern(C) int main()
{
    string value = "beta";
    switch (value)
    {
    case "alpha":
        return 1;
    case "beta":
        return 0;
    default:
        return 2;
    }
}
