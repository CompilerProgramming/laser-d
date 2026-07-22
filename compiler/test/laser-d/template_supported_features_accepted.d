// TEST_MODE: compilable

template Identity(T)
{
    alias Identity = T;
}

template Same(alias symbol)
{
    alias Same = symbol;
}

template Count(Items...)
{
    enum Count = Items.length;
}

alias Pointer(T) = T*;
enum twice(int value) = value * 2;

auto inferredIdentity(T)(T value)
{
    auto result = value;
    return result;
}

immutable(T) immutableIdentity(T)(T value)
{
    return value;
}

T sum(T)(T[] values)
{
    T result;
    foreach (value; values)
        result += value;
    return result;
}

ulong textLength(Character)(immutable(Character)[] text)
{
    return text.length;
}

T invokeFunction(T)(T function(T) operation, T value)
{
    return operation(value);
}

T invokeDelegate(T)(T delegate(T) operation, T value)
{
    return operation(value);
}

T withCleanup(T)(T value)
{
    T result;
    {
        scope(exit)
            result += value;
        result += 1;
    }
    return result;
}

struct Box(T)
{
    T value;

    T get()
    {
        return value;
    }
}

union Cell(T)
{
    T value;
    ubyte[(T.sizeof)] bytes;
}

template Choice(T)
{
    enum Choice : T
    {
        first = 1,
        second = 2,
    }
}

struct Packed(T)
    if (is(T == uint))
{
    T low : 4;
    T high : 4;
}

mixin template Stored(T)
{
    T stored;

    T load()
    {
        return stored;
    }
}

struct Mixed(T)
{
    mixin Stored!T;
}

int increment(int value)
{
    return value + 1;
}

static assert(is(Identity!bool == bool));
static assert(is(Identity!byte == byte));
static assert(is(Identity!ushort == ushort));
static assert(is(Identity!long == long));
static assert(is(Identity!float == float));
static assert(is(Identity!double == double));
static assert(is(Identity!char == char));
static assert(is(Identity!wchar == wchar));
static assert(is(Identity!dchar == dchar));
static assert(is(Identity!(typeof(null)) == typeof(null)));
static assert(is(Identity!(immutable(int)) == immutable(int)));
static assert(is(Pointer!int == int*));
static assert(__traits(isSame, Same!increment, increment));
static assert(Count!(int, uint, char) == 3);
static assert(twice!21 == 42);
static assert(is(typeof(inferredIdentity(1)) == int));
static assert(is(typeof(immutableIdentity(1)) == immutable(int)));
static assert(inferredIdentity(41) == 41);
static assert(immutableIdentity(42) == 42);
static assert(withCleanup(4) == 5);
alias IntegerBox = Box!int;
alias UnsignedCell = Cell!uint;
alias ShortChoice = Choice!ushort;
alias PackedUnsigned = Packed!uint;
static assert(is(IntegerBox == struct));
static assert(is(UnsignedCell == union));
static assert(is(ShortChoice == enum));
static assert(is(typeof(IntegerBox.value) == int));
static assert(is(typeof(UnsignedCell.value) == uint));
static assert(is(typeof(ShortChoice.first) == ShortChoice));
static assert(__traits(isBitfield, PackedUnsigned.low));
static assert(__traits(getBitfieldWidth, PackedUnsigned.low) == 4);

extern(C) int main()
{
    int[4] storage;
    storage[0] = 1;
    storage[1] = 2;
    storage[2] = 3;
    storage[3] = 4;
    int[] view = storage[];
    if (sum(view) != 10)
        return 1;

    if (textLength("laser") != 5 || textLength("wide"w) != 4 ||
        textLength("code"d) != 4)
        return 2;

    Box!int box = Box!int(7);
    if (box.get() != 7)
        return 3;

    Cell!uint cell;
    cell.value = 0x01020304;
    if (cell.value != 0x01020304)
        return 4;

    Packed!uint packed;
    packed.low = 3;
    packed.high = 12;
    if (packed.low != 3 || packed.high != 12)
        return 5;

    Mixed!int mixed;
    mixed.stored = 9;
    if (mixed.load() != 9)
        return 6;

    int function(int) functionPointer = &increment;
    if (invokeFunction(functionPointer, 10) != 11)
        return 7;

    int delegate(int) operation = (int value) => value * 2;
    if (invokeDelegate(operation, 6) != 12)
        return 8;

    Choice!ushort choice = Choice!ushort.second;
    return choice == Choice!ushort.second ? 0 : 9;
}
