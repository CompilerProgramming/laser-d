// TEST_MODE: compilable

int cleanupCount(int value)
{
    int result;
    {
        scope(exit)
            result += value;
        result += 1;
    }
    return result;
}

static assert(cleanupCount(4) == 5);
