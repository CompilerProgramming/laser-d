// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/super_rejected.d(15): Error: `super` is not supported in Laser-D because structs do not support inheritance
laser-d/super_rejected.d(19): Error: `super` is not supported in Laser-D because structs do not support inheritance
---
*/

struct Value
{
    void inspect()
    {
        auto base = super;
    }
}

static assert(is(Value == super));
