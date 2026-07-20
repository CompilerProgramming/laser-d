// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/module_lifecycle_rejected.d(13): Error: module lifecycle constructors are not supported in Laser-D
laser-d/module_lifecycle_rejected.d(17): Error: module lifecycle destructors are not supported in Laser-D
laser-d/module_lifecycle_rejected.d(23): Error: module lifecycle constructors are not supported in Laser-D
laser-d/module_lifecycle_rejected.d(26): Error: module lifecycle destructors are not supported in Laser-D
---
*/

static this()
{
}

static ~this()
{
}

struct LifecycleOwner
{
    static this()
    {
    }
    static ~this()
    {
    }
}
