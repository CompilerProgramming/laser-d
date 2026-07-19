// TEST_MODE: runnable

int moduleValue = 9;

extern(C) int main()
{
    bool booleanFalse = false;
    bool booleanTrue = true;
    int decimalInteger = 42;
    uint hexadecimalInteger = 0x2Au;
    long binaryInteger = 0b101010L;
    float singlePrecision = 1.5f;
    double doublePrecision = 2.5;
    char character = 'L';
    wchar wideCharacter = 'D';
    dchar unicodeCharacter = '\U0001F680';
    void* nullPointer = null;

    int identifierExpression = moduleValue;
    int parenthesizedExpression = (((identifierExpression)));
    int defaultConstructed = int();
    int explicitlyConstructed = int(42);
    double converted = double(explicitlyConstructed);

    if (booleanFalse || !booleanTrue)
        return 1;
    if (decimalInteger != 42 || hexadecimalInteger != 42 || binaryInteger != 42)
        return 2;
    if (singlePrecision != 1.5f || doublePrecision != 2.5)
        return 3;
    if (character != 'L' || wideCharacter != 'D' || unicodeCharacter != '\U0001F680')
        return 4;
    if (nullPointer !is null)
        return 5;
    if (parenthesizedExpression != 9 || defaultConstructed != 0)
        return 6;
    if (explicitlyConstructed != 42 || converted != 42.0)
        return 7;
    return 0;
}
