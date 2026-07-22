// TEST_MODE: fail_compilation

int answer()
{
    return 42;
}

int withDefault(int value = 7)
{
    return value;
}

int doubled(int value)
{
    return value * 2;
}

struct Counter
{
    int stored;

    int read()
    {
        return stored;
    }

    int amount()
    {
        return stored;
    }

    int amount(int replacement)
    {
        stored = replacement;
        return stored;
    }
}

void rejectedCalls()
{
    int first = answer;
    int second = withDefault;
    int third = Counter(3).read;
    int fourth = (5).doubled;

    Counter counter;
    counter.amount = 9;
}

/*
TEST_OUTPUT:
---
laser-d/optional_parentheses_rejected.d(41): Error: function calls require explicit `()` in Laser-D
laser-d/optional_parentheses_rejected.d(42): Error: function calls require explicit `()` in Laser-D
laser-d/optional_parentheses_rejected.d(43): Error: function calls require explicit `()` in Laser-D
laser-d/optional_parentheses_rejected.d(44): Error: function calls require explicit `()` in Laser-D
laser-d/optional_parentheses_rejected.d(47): Error: function calls require explicit `()` in Laser-D
---
*/
