// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/named_nested_functions_rejected.d(14): Error: named nested functions are not supported in Laser-D; use a module-level function or non-capturing function literal
laser-d/named_nested_functions_rejected.d(23): Error: named nested functions are not supported in Laser-D; use a module-level function or non-capturing function literal
laser-d/named_nested_functions_rejected.d(32): Error: named nested functions are not supported in Laser-D; use a module-level function or non-capturing function literal
---
*/

int capturing(int outerValue)
{
    int nested(int value)
    {
        return outerValue + value;
    }
    return nested(1);
}

int contextFree()
{
    int nested(int value)
    {
        return value + 1;
    }
    return nested(1);
}

int staticNested()
{
    static int nested(int value)
    {
        return value + 1;
    }
    return nested(1);
}
