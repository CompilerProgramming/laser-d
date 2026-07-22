// TEST_MODE: runnable

struct Pair
{
    int left;
    int right;
}

int cleanupTransfers()
{
    int cleanupCount;

cleanupLoop:
    for (int index; index < 3; ++index)
    {
        scope(exit) cleanupCount += 10;
        if (index == 0)
            continue;
        break cleanupLoop;
    }

    {
        scope(exit) cleanupCount += 100;
        goto cleanupComplete;
    }

cleanupComplete:
    return cleanupCount;
}

void cleanupReturn(ref int cleanupCount)
{
    scope(exit) ++cleanupCount;
    return;
}

extern(C) int main()
{
    int value;

outer:
    for (int row; row < 3; ++row)
    {
        for (int column; column < 3; ++column)
        {
            if (column == 1)
                continue;
            if (row == 2)
                break outer;
            value += row + column;
        }
    }

    goto selected;
    value = -100;

selected:
    value += 10;

    int selector = 1;
    switch (selector)
    {
    case 0:
        value = -200;
        goto default;
    case 1:
        value += 2;
        goto case 2;
    case 2:
        value += 3;
        break;
    default:
        value += 100;
        break;
    }

    Pair pair = Pair(4, 5);
    with (pair)
    {
        value += left + right;
    }

    if (cleanupTransfers() != 120)
        return 2;

    int cleanupCount;
    cleanupReturn(cleanupCount);
    if (cleanupCount != 1)
        return 3;

    return value == 30 ? 0 : 1;
}
