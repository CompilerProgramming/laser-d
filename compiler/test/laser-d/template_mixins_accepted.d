// TEST_MODE: compilable

mixin template DefineValue()
{
    enum generatedValue = 42;
}

mixin DefineValue!();

mixin template Members(T, T initial = T.init)
{
    T value = initial;

    T read()
    {
        return value;
    }
}

struct Container
{
    mixin Members!(int, 7);
}

union Storage
{
    mixin Members!uint namedMembers;
}

mixin template LocalValue(T)
    if (is(T == int))
{
    T localValue = 9;
}

template Wrapped(T)
{
    struct Result
    {
        mixin Members!T;
    }
}

static assert(generatedValue == 42);
static assert(Container.init.value == 7);
static assert(Container(11).read() == 11);
static assert(is(typeof(Storage.init.namedMembers.value) == uint));
static assert(is(typeof(Wrapped!long.Result.value) == long));

extern(C) int main()
{
    mixin LocalValue!int;

    Storage storage;
    storage.namedMembers.value = 12;

    Wrapped!long.Result wrapped;
    wrapped.value = 14;

    if (localValue != 9)
        return 1;
    if (storage.namedMembers.read() != 12)
        return 2;
    return wrapped.read() == 14 ? 0 : 3;
}
