// TEST_MODE: runnable

int value(int result)
{
    return result;
}

int* addressOf(int* result)
{
    return result;
}

extern(C) int main()
{
    int total;

    if (auto inferred = value(3))
    {
        static assert(is(typeof(inferred) == int));
        total += inferred;
    }
    else
        return 1;

    if (long explicitlyTyped = value(4))
    {
        static assert(is(typeof(explicitlyTyped) == long));
        total += explicitlyTyped;
    }
    else
        return 2;

    int storage = 5;
    if (int* pointer = addressOf(&storage))
        total += *pointer;
    else
        return 3;

    if (auto falseValue = value(0))
        return 4;
    else
        static assert(!__traits(compiles, falseValue));

    static assert(!__traits(compiles, inferred));
    static assert(!__traits(compiles, explicitlyTyped));
    static assert(!__traits(compiles, pointer));

    return total == 12 ? 0 : 5;
}
