// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/constructor_delegation_rejected.d(23): Error: constructor delegation is not supported in Laser-D; initialize fields directly
---
*/

struct Pair
{
    int first;
    int second;

    this(int first, int second)
    {
        this.first = first;
        this.second = second;
    }

    this(int value)
    {
        this(value, value);
    }
}
