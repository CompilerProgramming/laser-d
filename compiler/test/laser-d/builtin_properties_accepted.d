// TEST_MODE: runnable

struct Record
{
    int number;
    ushort code;
}

struct ImaginaryNamedField
{
    int im;
}

union Storage
{
    uint unsignedValue;
    int signedValue;
}

enum Choice : ushort
{
    first = 2,
    second = 5,
}

int increment(int value)
{
    return value + 1;
}

static assert(int.init == 0);
static assert(int.sizeof == 4);
static assert(int.alignof >= 1);
static assert(int.min < 0 && int.max > 0);
static assert(float.infinity > float.max);
static assert(double.infinity > double.max);
static assert(float.min_normal > 0);
static assert(is(typeof(float.nan) == float));
static assert(is(typeof(double.nan) == double));
static assert((1.5).re == 1.5);
static assert(ImaginaryNamedField(4).im == 4);
static assert(int.stringof == "int");
static assert(int.mangleof == "i");
static assert((1 + 2).stringof == "1 + 2");
static assert(Record.init.number == 0);
static assert(Record.tupleof.length == 2);
static assert(Record.number.offsetof == 0);
static assert(Record.sizeof >= int.sizeof + ushort.sizeof);
static assert(Storage.signedValue.offsetof == 0);
static assert(Choice.init == Choice.first);
static assert(Choice.min == Choice.first);
static assert(Choice.max == Choice.second);
static assert(Choice.sizeof == ushort.sizeof);

extern(C) int main()
{
    int[4] storage;
    storage[0] = 10;
    storage[1] = 20;
    storage[2] = 30;
    storage[3] = 40;
    int[] view = storage[1 .. 3];

    if (storage.length != 4 || view.length != 2)
        return 1;
    if (storage.ptr is null || view.ptr !is storage.ptr + 1)
        return 2;

    int function(int) functionPointer = &increment;
    if (functionPointer(4) != 5)
        return 3;

    int offset = 7;
    int delegate(int) operation = (int value) => value + 1;
    if (operation.ptr !is null || operation.funcptr is null || operation(offset) != 8)
        return 4;

    Record record = Record(6, 9);
    int total;
    foreach (field; record.tupleof)
        total += field;
    return total == 15 ? 0 : 5;
}
