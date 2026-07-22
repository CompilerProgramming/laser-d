// TEST_MODE: fail_compilation

struct Gauge
{
    @property int value()
    {
        return 0;
    }

    @property int value(int replacement)
    {
        return replacement;
    }

    @property int doubled() immutable
    {
        return 0;
    }
}

@property int squared(int value)
{
    return value * value;
}

/*
TEST_OUTPUT:
---
laser-d/property_functions_rejected.d(5): Error: attribute `@property` is not supported in Laser-D; call functions explicitly
laser-d/property_functions_rejected.d(10): Error: attribute `@property` is not supported in Laser-D; call functions explicitly
laser-d/property_functions_rejected.d(15): Error: attribute `@property` is not supported in Laser-D; call functions explicitly
laser-d/property_functions_rejected.d(21): Error: attribute `@property` is not supported in Laser-D; call functions explicitly
---
*/
