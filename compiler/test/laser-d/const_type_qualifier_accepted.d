// TEST_MODE: runnable

alias ReadOnlyInteger = const(int);
alias ReadOnlyPointer = const(char)*;

int readPointer(const int* value)
{
    return *value;
}

T readValue(T)(const T* value)
{
    return *value;
}

extern(C) int main()
{
    int mutableValue = 41;
    const int localValue = mutableValue + 1;
    const(int)* pointer = &mutableValue;

    static assert(is(ReadOnlyInteger == const(int)));
    static assert(is(ReadOnlyPointer == const(char)*));
    static assert(is(typeof(localValue) == const(int)));

    if (localValue != 42)
        return 1;
    if (readPointer(pointer) != 41)
        return 2;
    if (readValue(&mutableValue) != 41)
        return 3;

    return 0;
}
