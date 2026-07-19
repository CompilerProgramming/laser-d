// TEST_MODE: compilable

enum manifestConstant = 42;
alias Integer = int;

extern(C) int main()
{
    bool booleanValue;
    byte signedByte;
    ubyte unsignedByte;
    short signedShort;
    ushort unsignedShort;
    int signedInteger;
    uint unsignedInteger;
    long signedLong;
    ulong unsignedLong;
    float floatValue;
    double doubleValue;
    char utf8CodeUnit;
    wchar utf16CodeUnit;
    dchar utf32CodeUnit;
    typeof(null) nullValue;

    static assert(booleanValue.init == false);
    static assert(signedByte.init == 0);
    static assert(unsignedLong.init == 0);
    static assert(char.init == '\xFF');
    static assert(wchar.init == '\uFFFF');
    static assert(dchar.init == '\U0000FFFF');
    static assert(nullValue.init is null);

    Integer aliasedTypeValue = manifestConstant;
    alias aliasedSymbol = aliasedTypeValue;
    int inferred = 1;
    auto automaticallyTyped = inferred;
    int first = 2, second = 3;
    int deliberatelyUninitialized = void;

    static assert(is(typeof(automaticallyTyped) == int));
    return aliasedSymbol + automaticallyTyped + first + second == 48 ? 0 : 1;
}
