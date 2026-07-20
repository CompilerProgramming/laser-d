// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/mutable_static_storage_rejected.d(11): Error: variable `mutable_static_storage_rejected.mutableGlobal` uses mutable global or static storage, which is not supported in Laser-D
laser-d/mutable_static_storage_rejected.d(15): Error: variable `mutable_static_storage_rejected.StaticState.value` uses mutable global or static storage, which is not supported in Laser-D
---
*/

int mutableGlobal;

struct StaticState
{
    static int value;
}
