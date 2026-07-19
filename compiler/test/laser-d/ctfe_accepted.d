// TEST_MODE: compilable

int factorial(int value)
{
    int result = 1;
    for (int current = 2; current <= value; ++current)
        result *= current;
    return result;
}

int staticForeachSum()
{
    int result;
    static foreach (value; 0 .. 5)
        result += value;
    return result;
}

int compileTimeBranch()
{
    if (__ctfe)
        return 42;
    return 0;
}

enum factorialOfFive = factorial(5);
enum foreachResult = staticForeachSum();

static if (factorialOfFive == 120)
    enum selectedValue = 42;
else
    static assert(false);

alias FixedStorage = int[factorial(3)];

static assert(factorialOfFive == 120);
static assert(foreachResult == 10);
static assert(selectedValue == 42);
static assert(compileTimeBranch() == 42);
static assert(FixedStorage.length == 6);
