// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/mutable_local_static_storage_rejected.d(12): Error: variable `mutable_local_static_storage_rejected.remember.value` uses mutable global or static storage, which is not supported in Laser-D
---
*/

int remember()
{
    static int value;
    return value;
}
