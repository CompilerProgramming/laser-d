// TEST_MODE: runnable

immutable int rootValue = 9;

T identity(T)(T value)
{
    return value;
}

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

    int identifierExpression = .rootValue;
    int parenthesizedExpression = (((identifierExpression)));
    int defaultConstructed = int();
    int explicitlyConstructed = int(42);
    double converted = double(explicitlyConstructed);
    int rootTemplateResult = .identity!int(42);

    int[3] fixedValues;
    fixedValues[0] = 10;
    fixedValues[1] = 20;
    fixedValues[2] = 30;
    int lastValue = fixedValues[$ - 1];

    int function(int) explicitFunctionLiteral =
        function int(int value) { return value + 1; };

    static assert(is(typeof(identifierExpression) == int));
    static assert(int.sizeof > 0);
    static assert((int).sizeof == int.sizeof);
    static assert(__FILE__.length > 0);
    static assert(__FILE_FULL_PATH__.length >= __FILE__.length);
    static assert(__MODULE__.length > 0);
    static assert(__LINE__ > 0);
    static assert(__FUNCTION__.length > 0);
    static assert(__PRETTY_FUNCTION__.length >= __FUNCTION__.length);

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
    if (rootTemplateResult != 42 || lastValue != 30)
        return 8;
    if (explicitFunctionLiteral(41) != 42)
        return 9;
    return 0;
}
