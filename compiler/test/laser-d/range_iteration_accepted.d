// TEST_MODE: runnable

struct Range
{
    int current;
    int limit;

    bool empty()
    {
        return current >= limit;
    }

    int front()
    {
        return current;
    }

    void popFront()
    {
        ++current;
    }

    int back()
    {
        return limit - 1;
    }

    void popBack()
    {
        --limit;
    }
}

extern(C) int main()
{
    Range values;
    values.limit = 4;

    int forward;
    foreach (value; values)
        forward = forward * 10 + value;

    int reverse;
    foreach_reverse (value; values)
        reverse = reverse * 10 + value;

    return forward == 123 && reverse == 3210 ? 0 : 1;
}
