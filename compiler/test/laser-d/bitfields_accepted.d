// TEST_MODE: runnable

struct Flags
{
    uint low : 3 = 1;
    uint high : 5 = 2;
    uint : 0;
    int signedValue : 4;
}

union Overlay
{
    uint whole;
    uint low : 4;
}

static assert(__traits(isBitfield, Flags.low));
static assert(__traits(isBitfield, Flags.high));
static assert(__traits(getBitfieldWidth, Flags.low) == 3);
static assert(__traits(getBitfieldWidth, Flags.high) == 5);
static assert(Flags.low.min == 0);
static assert(Flags.low.max == 7);
static assert(Flags.signedValue.min == -8);
static assert(Flags.signedValue.max == 7);

extern(C) int main()
{
    Flags flags;
    if (flags.low != 1 || flags.high != 2)
        return 1;

    flags.low = 6;
    flags.high = 17;
    flags.signedValue = -3;
    if (flags.low != 6 || flags.high != 17 || flags.signedValue != -3)
        return 2;

    Overlay overlay;
    overlay.whole = 0;
    overlay.low = 9;
    return overlay.low == 9 ? 0 : 3;
}
