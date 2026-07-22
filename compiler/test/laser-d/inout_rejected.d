// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/inout_rejected.d(13): Error: `inout` is not supported in Laser-D because qualifier wildcard matching is disabled
laser-d/inout_rejected.d(15): Error: `inout` is not supported in Laser-D because qualifier wildcard matching is disabled
laser-d/inout_rejected.d(15): Error: `inout` is not supported in Laser-D because qualifier wildcard matching is disabled
laser-d/inout_rejected.d(21): Error: `inout` is not supported in Laser-D because qualifier wildcard matching is disabled
---
*/

alias WildInteger = inout(int);

inout(int)* preserve(inout(int)* value);

struct Value
{
    int number;

    int read() inout
    {
        return number;
    }
}
