// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/mutable_static_storage_rejected.d(12): Error: variable `mutable_static_storage_rejected.mutableGlobal` uses mutable global or static storage, which is not supported in Laser-D
laser-d/mutable_static_storage_rejected.d(13): Error: variable `mutable_static_storage_rejected.constantGlobal` uses mutable global or static storage, which is not supported in Laser-D
laser-d/mutable_static_storage_rejected.d(17): Error: variable `mutable_static_storage_rejected.StaticState.value` uses mutable global or static storage, which is not supported in Laser-D
---
*/

int mutableGlobal;
const int constantGlobal = 1;

struct StaticState
{
    static int value;
}
