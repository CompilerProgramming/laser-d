// TEST_MODE: compilable

struct Box(T)
{
    T value;

    this(T initial)
    {
        value = initial;
    }

    T get()
    {
        return value;
    }
}

struct Converted
{
    int value;

    this(T)(T initial)
    {
        value = cast(int) initial;
    }
}

static assert(Box!int(7).get() == 7);
static assert(Converted(cast(short) 9).value == 9);
