// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/ref_returns_rejected.d(11): Error: `ref` return values are not supported in Laser-D
laser-d/ref_returns_rejected.d(16): Error: `ref` return values are not supported in Laser-D
---
*/

ref int returnReference(ref int storage)
{
    return storage;
}

auto literal = ref (ref int storage) => storage;
