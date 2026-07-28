// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/receiver_lifetime_qualifiers_rejected.d(15): Error: `return` function qualifiers are not supported in Laser-D; receiver lifetime relationships are inferred
laser-d/receiver_lifetime_qualifiers_rejected.d(25): Error: `scope` function qualifiers are not supported in Laser-D; receiver lifetime relationships are inferred
---
*/

struct Returned
{
    int value;

    int* pointer() return
    {
        return &value;
    }
}

struct Scoped
{
    int value;

    int* pointer() scope
    {
        return &value;
    }
}
