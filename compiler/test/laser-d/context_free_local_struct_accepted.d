// TEST_MODE: runnable

extern(C) int main()
{
    struct Pair
    {
        int first;
        int second;
    }

    Pair value = Pair(2, 3);
    return value.first + value.second == 5 ? 0 : 1;
}
