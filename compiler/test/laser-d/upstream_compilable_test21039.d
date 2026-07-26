// TEST_MODE: compilable
// Upstream source: compiler/test/compilable/test21039.d
// https://github.com/dlang/dmd/issues/21039

struct A
{
    const(char)[0] b = 0;
}

struct B
{
    int[0] x = 5 + 5;
}
