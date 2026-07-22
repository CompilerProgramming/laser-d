// TEST_MODE: runnable

template Values(T...)
{
    alias Values = T;
}

extern(C) int main()
{
    int ordinarySum;
    foreach (value; Values!(1, 2, 3))
        ordinarySum += value;

    int staticSum;
    static foreach (value; Values!(4, 5, 6))
        staticSum += value;

    return ordinarySum == 6 && staticSum == 15 ? 0 : 1;
}
