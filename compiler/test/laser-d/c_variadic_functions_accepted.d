// TEST_MODE: runnable

extern(C) int firstArgument(int first, ...)
{
    return first;
}

alias CVariadicFunction = extern(C) int function(int, ...);

static assert(__traits(getFunctionVariadicStyle, firstArgument) == "stdarg");
static assert(__traits(getFunctionVariadicStyle, CVariadicFunction) == "stdarg");

extern(C) int main()
{
    CVariadicFunction functionPointer = &firstArgument;

    if (firstArgument(42, 1, 2.0) != 42)
        return 1;
    return functionPointer(42, cast(byte) 3, cast(float) 4.0) == 42 ? 0 : 2;
}
