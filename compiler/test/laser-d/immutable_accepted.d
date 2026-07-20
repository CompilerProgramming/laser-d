// TEST_MODE: compilable

int produce(int value)
{
    return value + 1;
}

struct Value
{
    int number;

    int read() immutable
    {
        return number;
    }
}

int inspect(int input)
{
    immutable int runtimeValue = produce(input);
    immutable(int) qualifiedValue = runtimeValue;
    immutable Value aggregate = Value(qualifiedValue);
    return aggregate.read();
}

static assert(inspect(4) == 5);
