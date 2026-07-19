// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/new_expressions_rejected.d(17): Error: `new` expressions are not supported in Laser-D because implicit allocation is disabled
laser-d/new_expressions_rejected.d(18): Error: `new` expressions are not supported in Laser-D because implicit allocation is disabled
laser-d/new_expressions_rejected.d(21): Error: `new` expressions are not supported in Laser-D because implicit allocation is disabled
---
*/

struct Item
{
    int value;
}

auto scalar = new int;
auto aggregate = new Item;

ubyte[4] storage;
auto placed = new (storage) Item;
