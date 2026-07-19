// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/array_gc_properties_rejected.d(15): Error: GC-backed array property `dup` is not supported in Laser-D
laser-d/array_gc_properties_rejected.d(16): Error: GC-backed array property `idup` is not supported in Laser-D
laser-d/array_gc_properties_rejected.d(21): Error: GC-backed array property `capacity` is not supported in Laser-D
laser-d/array_gc_properties_rejected.d(26): Error: assignment to dynamic array `.length` is not supported in Laser-D
---
*/

void duplicate(int[] values)
{
    auto mutableCopy = values.dup;
    auto immutableCopy = values.idup;
}

void manageCapacity(int[] values)
{
    auto available = values.capacity;
}

void resize(int[] values)
{
    values.length = 16;
}
