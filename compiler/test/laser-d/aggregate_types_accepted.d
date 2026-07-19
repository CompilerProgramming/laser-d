// TEST_MODE: runnable

int copies;
int destructions;

struct Point
{
    int x;
    int y;

    int sum()
    {
        return x + y;
    }
}

struct Resource
{
    int value;

    this(int value)
    {
        this.value = value;
    }

    this(this)
    {
        copies++;
    }

    ~this()
    {
        destructions++;
    }
}

union Word
{
    uint whole;
    ushort half;

    this(uint value)
    {
        whole = value;
    }
}

struct TaggedValue
{
    int tag;
    union
    {
        int integer;
        float floating;
    }
}

enum Colour : ubyte
{
    red = 1,
    green,
    blue = 4,
}

enum
{
    manifestValue = 7,
}

enum Opaque : ushort;

static assert(Point.sizeof == 2 * int.sizeof);
static assert(Point.x.offsetof == 0);
static assert(Point.y.offsetof == int.sizeof);
static assert(Word.sizeof == uint.sizeof);
static assert(Word.whole.offsetof == 0);
static assert(Word.half.offsetof == 0);
static assert(Colour.min == Colour.red);
static assert(Colour.max == Colour.blue);
static assert(Colour.init == Colour.red);
static assert(manifestValue == 7);
static assert(Opaque.sizeof == ushort.sizeof);

extern(C) int main()
{
    Point point = Point(2, 3);
    if (point.sum() != 5)
        return 1;

    Word word = Word(42);
    if (word.whole != 42)
        return 2;

    TaggedValue tagged;
    tagged.tag = 1;
    tagged.integer = 9;
    if (tagged.integer != 9)
        return 3;

    {
        Resource first = Resource(11);
        Resource second = first;
        if (second.value != 11 || copies != 1)
            return 4;
    }

    return destructions == 2 ? 0 : 5;
}
