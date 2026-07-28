// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/receiver_lifetime_inference.d(23): Error: returning `value.pointer()` escapes a reference to local variable `value`
---
*/

struct Box(T)
{
    T value;

    T* pointer()
    {
        return &value;
    }
}

int* escape()
{
    Box!int value;
    return value.pointer();
}
