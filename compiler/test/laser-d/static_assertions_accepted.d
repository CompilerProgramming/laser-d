// TEST_MODE: compilable

enum square(int value) = value * value;

static assert(1 + 1 == 2);
static assert(square!6 == 36, "compile-time message form must work");

template Same(T, U)
{
    enum Same = is(T == U);
}

static assert(Same!(int, int));

struct Value
{
    int number;
}

static assert(Value.sizeof == int.sizeof);
