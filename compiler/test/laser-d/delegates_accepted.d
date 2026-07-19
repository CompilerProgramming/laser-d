// TEST_MODE: runnable

int invoke(scope int delegate(int) operation, int value)
{
    return operation(value);
}

struct Accumulator
{
    int offset;

    int add(int value)
    {
        return offset + value;
    }
}

extern(C) int main()
{
    int delegate(int) stateless = (int value) => value * 2;
    if (invoke(stateless, 6) != 12)
        return 1;

    Accumulator accumulator = Accumulator(20);
    int delegate(int) member = &accumulator.add;
    if (invoke(member, 2) != 22)
        return 2;

    return 0;
}
