// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/user_defined_attributes_rejected.d(14): Error: user-defined attributes are not supported in Laser-D
laser-d/user_defined_attributes_rejected.d(16): Error: user-defined attributes are not supported in Laser-D
laser-d/user_defined_attributes_rejected.d(16): Error: user-defined attributes are not supported in Laser-D
laser-d/user_defined_attributes_rejected.d(23): Error: user-defined attributes are not supported in Laser-D
laser-d/user_defined_attributes_rejected.d(28): Error: user-defined attributes are not supported in Laser-D
---
*/

@("global") int globalValue;

@marker int annotatedFunction(@("parameter") int value)
{
    return value;
}

struct Container
{
    @(1, "member") int member;
}

enum Choice
{
    @choiceMetadata selected
}
