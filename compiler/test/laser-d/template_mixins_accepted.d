// TEST_MODE: compilable

mixin template DefineValue()
{
    enum generatedValue = 42;
}

mixin DefineValue!();

mixin template Members(T)
{
    T value;
}

struct Container
{
    mixin Members!int;
}

static assert(generatedValue == 42);
static assert(Container.sizeof == int.sizeof);
