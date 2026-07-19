// TEST_MODE: compilable

// Every function type carries the mandatory Laser-D attributes.
void ordinary()
{
}

extern(C) void externalFunction();
void function() functionPointer;
void delegate() delegateValue;

auto inferredReturnType()
{
    return 1;
}

struct Aggregate
{
    void memberFunction()
    {
    }
}

void functionForms()
{
    void nestedFunction()
    {
    }

    auto lambda = () {};

    static assert(hasAttribute!(nestedFunction, "nothrow"));
    static assert(hasAttribute!(nestedFunction, "@nogc"));
    static assert(hasAttribute!(lambda, "nothrow"));
    static assert(hasAttribute!(lambda, "@nogc"));
}

enum bool hasAttribute(alias functionSymbol, immutable(char)[] expected) = ()
{
    foreach (attribute; __traits(getFunctionAttributes, functionSymbol))
        if (attribute == expected)
            return true;
    return false;
}();

static assert(__traits(getFunctionAttributes, ordinary).length >= 2);
static assert(hasAttribute!(ordinary, "nothrow"));
static assert(hasAttribute!(ordinary, "@nogc"));
static assert(hasAttribute!(externalFunction, "nothrow"));
static assert(hasAttribute!(externalFunction, "@nogc"));
static assert(hasAttribute!(functionPointer, "nothrow"));
static assert(hasAttribute!(functionPointer, "@nogc"));
static assert(hasAttribute!(delegateValue, "nothrow"));
static assert(hasAttribute!(delegateValue, "@nogc"));
static assert(hasAttribute!(inferredReturnType, "nothrow"));
static assert(hasAttribute!(inferredReturnType, "@nogc"));
static assert(hasAttribute!(Aggregate.memberFunction, "nothrow"));
static assert(hasAttribute!(Aggregate.memberFunction, "@nogc"));

extern(C) int main()
{
    return 0;
}
