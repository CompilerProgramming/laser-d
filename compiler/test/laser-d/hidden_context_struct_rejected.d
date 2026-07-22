// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/hidden_context_struct_rejected.d(14): Error: nested structs requiring a hidden context are not supported in Laser-D
---
*/

int enclosing()
{
    int outerValue = 3;

    struct Capturing
    {
        int value()
        {
            return outerValue;
        }
    }

    Capturing value;
    return value.value();
}
