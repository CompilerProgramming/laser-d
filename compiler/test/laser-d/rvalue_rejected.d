// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/rvalue_rejected.d(20): Error: `__rvalue` is not supported in Laser-D because explicit move and ownership hints are disabled
laser-d/rvalue_rejected.d(23): Error: `__rvalue` is not supported in Laser-D because explicit move and ownership hints are disabled
---
*/

struct Value
{
    int number;
}

void consume(Value value);

void forceTemporary(ref Value value)
{
    consume(__rvalue(value));
}

ref Value markTemporary(ref Value value) __rvalue
{
    return value;
}
