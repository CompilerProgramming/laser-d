// TEST_MODE: runnable

struct Number
{
    int value;

    Number opUnary(immutable(char)[] operator : "-")()
    {
        return Number(-value);
    }

    Number opUnary(immutable(char)[] operator : "++")()
    {
        ++value;
        return this;
    }

    Number opBinary(immutable(char)[] operator : "+")(Number right)
    {
        return Number(value + right.value);
    }

    Number opBinaryRight(immutable(char)[] operator : "+")(int left)
    {
        return Number(left + value);
    }

    void opOpAssign(immutable(char)[] operator : "+")(int right)
    {
        value += right;
    }

    void opAssign(int replacement)
    {
        value = replacement;
    }

    bool opEquals(Number right)
    {
        return value == right.value;
    }

    int opCmp(Number right)
    {
        return value < right.value ? -1 : value > right.value ? 1 : 0;
    }

    T opCast(T)()
        if (is(T == bool) || is(T == int))
    {
        static if (is(T == bool))
            return value != 0;
        else
            return value;
    }

    int opCall(int scale)
    {
        return value * scale;
    }
}

struct Buffer
{
    int[4] storage;

    int opIndex(ulong index)
    {
        return storage[index];
    }

    void opIndexAssign(int value, ulong index)
    {
        storage[index] = value;
    }

    void opIndexOpAssign(immutable(char)[] operator : "+")(int value, ulong index)
    {
        storage[index] += value;
    }

    int[] opSlice(ulong lower, ulong upper)
    {
        return storage[lower .. upper];
    }

    void opSliceAssign(int value, ulong lower, ulong upper)
    {
        storage[lower .. upper] = value;
    }

    ulong opDollar()
    {
        return storage.length;
    }
}

struct Forwarded
{
    int opDispatch(immutable(char)[] name)(int value)
        if (name == "twice")
    {
        return value * 2;
    }
}

struct ImmutableNumber
{
    int value;

    bool opEquals(immutable(ImmutableNumber) right) immutable
    {
        return value == right.value;
    }
}

static assert(Number(6)(7) == 42);
static assert(cast(int) Number(9) == 9);
static assert(cast(bool) Number(1));
static assert(!cast(bool) Number(0));
static assert(Forwarded().twice(5) == 10);

extern(C) int main()
{
    Number first = Number(4);
    Number second = Number(3);

    if ((-first).value != -4)
        return 1;
    if ((first + second).value != 7 || (10 + second).value != 13)
        return 2;
    if (!(first == Number(4)) || first != Number(4))
        return 3;
    if (!(second < first) || !(first > second))
        return 4;

    first += 5;
    if (first.value != 9)
        return 5;
    first = 12;
    if (first.value != 12 || first(3) != 36)
        return 6;

    Number before = first++;
    if (before.value != 12 || first.value != 13)
        return 7;

    Buffer buffer;
    buffer[0] = 1;
    buffer[1] = 2;
    buffer[2] = 3;
    buffer[3] = 4;
    if (buffer[2] != 3 || buffer[$ - 1] != 4)
        return 8;

    buffer[1] += 5;
    if (buffer[1] != 7)
        return 9;

    buffer[1 .. 3] = 8;
    int[] middle = buffer[1 .. 3];
    if (middle.length != 2 || middle[0] != 8 || middle[1] != 8)
        return 10;

    Forwarded forwarded;
    if (forwarded.twice(6) != 12)
        return 11;

    immutable ImmutableNumber immutableLeft = ImmutableNumber(5);
    immutable ImmutableNumber immutableRight = ImmutableNumber(5);
    return immutableLeft == immutableRight ? 0 : 12;
}
