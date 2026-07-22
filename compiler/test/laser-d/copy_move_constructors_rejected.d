// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/copy_move_constructors_rejected.d(14): Error: user-defined struct copy constructors are not supported in Laser-D
laser-d/copy_move_constructors_rejected.d(23): Error: user-defined struct move constructors are not supported in Laser-D
---
*/

struct Copyable
{
    int value;
    this(ref Copyable source)
    {
        value = source.value;
    }
}

struct Movable
{
    int value;
    this(Movable source)
    {
        value = source.value;
    }
}
