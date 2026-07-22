// TEST_MODE: runnable

enum Mode
{
    first,
    second,
    third,
}

extern(C) int main()
{
    int total;

    if (true)
        total += 1;
    else
        return 1;

    int whileIndex;
    while (whileIndex < 3)
    {
        ++whileIndex;
        if (whileIndex == 2)
            continue;
        total += whileIndex;
    }

    int doIndex;
    do
    {
        ++doIndex;
        total += doIndex;
    }
    while (doIndex < 2);

    for (int index; index < 5; ++index)
    {
        if (index == 3)
            break;
        total += index;
    }

    int[4] values;
    values[0] = 1;
    values[1] = 2;
    values[2] = 3;
    values[3] = 4;
    foreach (value; values)
        total += value;

    foreach (ref value; values[])
        value += 1;

    foreach_reverse (index, value; values)
        total += cast(int) index + value;

    foreach (value; 1 .. 4)
        total += value;

    foreach_reverse (value; 1 .. 4)
        total += value;

    Mode mode = Mode.second;
    final switch (mode)
    {
    case Mode.first:
        return 2;
    case Mode.second:
        total += 5;
        break;
    case Mode.third:
        return 3;
    }

    switch (total)
    {
    case 45: .. case 60:
        total += 1;
        break;
    default:
        return 4;
    }

    return total == 59 ? 0 : 5;
}
