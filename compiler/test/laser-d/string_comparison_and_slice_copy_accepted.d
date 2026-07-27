// TEST_MODE: runnable

bool equal(string left, string right)
{
    return left == right;
}

void copy(char[] destination, char[] source)
{
    destination[] = source[];
}

bool sameView(string left, string right)
{
    return left is right;
}

extern(C) int main()
{
    string text = "Laser-D";
    if (!equal(text, "Laser-D") || equal(text, "laser-d"))
        return 1;
    if (!sameView(text, text[]))
        return 2;

    char[3] source;
    source[0] = 'D';
    source[1] = 'M';
    source[2] = 'D';
    char[3] destination;
    copy(destination[], source[]);
    if (destination[0] != 'D' || destination[1] != 'M' || destination[2] != 'D')
        return 3;

    return 0;
}
