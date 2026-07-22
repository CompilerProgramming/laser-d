// TEST_MODE: fail_compilation

int expressionPrecondition(int value)
in (value > 0)
{
    return value;
}

int blockPrecondition(int value)
in
{
    assert(value > 0);
}
do
{
    return value;
}

int expressionPostcondition(int value)
out (result; result > 0)
{
    return value;
}

int blockPostcondition(int value)
out (result)
{
    assert(result > 0);
}
do
{
    return value;
}

int contractStyleBody()
do
{
    return 1;
}

struct Checked(T)
{
    T read(T value)
    in (value > 0)
    {
        return value;
    }
}

/*
TEST_OUTPUT:
---
laser-d/function_contracts_rejected.d(4): Error: `in` function contracts are not supported in Laser-D
laser-d/function_contracts_rejected.d(10): Error: `in` function contracts are not supported in Laser-D
laser-d/function_contracts_rejected.d(14): Error: contract-style `do` function bodies are not supported in Laser-D; use `{ ... }`
laser-d/function_contracts_rejected.d(20): Error: `out` function contracts are not supported in Laser-D
laser-d/function_contracts_rejected.d(26): Error: `out` function contracts are not supported in Laser-D
laser-d/function_contracts_rejected.d(30): Error: contract-style `do` function bodies are not supported in Laser-D; use `{ ... }`
laser-d/function_contracts_rejected.d(36): Error: contract-style `do` function bodies are not supported in Laser-D; use `{ ... }`
laser-d/function_contracts_rejected.d(44): Error: `in` function contracts are not supported in Laser-D
---
*/
