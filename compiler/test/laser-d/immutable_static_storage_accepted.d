// TEST_MODE: compilable

immutable int immutableGlobal = 11;
enum manifestValue = 13;

struct Constants
{
    static immutable int value = 17;
}

static assert(immutableGlobal == 11);
static assert(manifestValue == 13);
static assert(Constants.value == 17);
