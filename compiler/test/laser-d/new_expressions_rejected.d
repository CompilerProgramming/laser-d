// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/new_expressions_rejected.d(19): Error: `new` expressions are not supported in Laser-D because implicit allocation is disabled
laser-d/new_expressions_rejected.d(20): Error: `new` expressions are not supported in Laser-D because implicit allocation is disabled
laser-d/new_expressions_rejected.d(23): Error: `new` expressions are not supported in Laser-D because implicit allocation is disabled
---
*/

struct Item
{
    int value;
}

void allocate()
{
    auto scalar = new int;
    auto aggregate = new Item;

    ubyte[4] storage;
    auto placed = new (storage) Item;
}
