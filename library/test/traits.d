import core.stdc.stdlib : EXIT_SUCCESS;
import std.traits;

private struct Record
{
    int number;
    const(char)[] text;
}

private int functionUnderTest(short value, const(char)[] text)
{
    return value + cast(int) text.length;
}

static assert(is(ConstOf!int == const int));
static assert(is(ImmutableOf!(const int) == immutable int));
static assert(is(ReturnType!functionUnderTest == int));
static assert(arity!functionUnderTest == 2);
static assert(is(Parameters!functionUnderTest[0] == short));
static assert(is(Parameters!functionUnderTest[1] == const(char)[]));
static assert(Fields!Record.length == 2);
static assert(is(Fields!Record[0] == int));
static assert(hasMember!(Record, "number"));
static assert(!hasMember!(Record, "missing"));
static assert(isIntegral!long);
static assert(isFloatingPoint!double);
static assert(isNumeric!uint);
static assert(isSomeChar!dchar);
static assert(isSomeString!(const(char)[]));
static assert(isStaticArray!(int[3]));
static assert(isDynamicArray!(int[]));
static assert(isArray!(int[3]));
static assert(isPointer!(int*));
static assert(is(PointerTarget!(int*) == int));
static assert(isAggregateType!Record);
static assert(isImplicitlyConvertible!(ubyte, int));
static assert(is(Select!(true, int, long) == int));

extern(C) int main()
{
    return EXIT_SUCCESS;
}
