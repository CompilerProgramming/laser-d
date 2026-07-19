// TEST_MODE: compilable

// Every function type carries the mandatory Laser-D attributes.
void ordinary()
{
}

extern(C) void externalFunction();

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
    void function() functionPointer;
    void delegate() delegateValue;
    void nestedFunction()
    {
    }

    auto lambda = () {};

    static assert(hasAttribute!(nestedFunction, "nothrow"));
    static assert(hasAttribute!(nestedFunction, "@nogc"));
    static assert(hasAttribute!(nestedFunction, "@system"));
    static assert(hasAttribute!(lambda, "nothrow"));
    static assert(hasAttribute!(lambda, "@nogc"));
    static assert(hasAttribute!(lambda, "@system"));
    static assert(!hasAttribute!(nestedFunction, "pure"));
    static assert(!hasAttribute!(lambda, "pure"));

    static assert(hasAttribute!(functionPointer, "nothrow"));
    static assert(hasAttribute!(functionPointer, "@nogc"));
    static assert(hasAttribute!(functionPointer, "@system"));
    static assert(hasAttribute!(delegateValue, "nothrow"));
    static assert(hasAttribute!(delegateValue, "@nogc"));
    static assert(hasAttribute!(delegateValue, "@system"));
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
static assert(hasAttribute!(ordinary, "@system"));
static assert(!hasAttribute!(ordinary, "pure"));
static assert(hasAttribute!(externalFunction, "nothrow"));
static assert(hasAttribute!(externalFunction, "@nogc"));
static assert(hasAttribute!(externalFunction, "@system"));
static assert(hasAttribute!(inferredReturnType, "nothrow"));
static assert(hasAttribute!(inferredReturnType, "@nogc"));
static assert(hasAttribute!(inferredReturnType, "@system"));
static assert(hasAttribute!(Aggregate.memberFunction, "nothrow"));
static assert(hasAttribute!(Aggregate.memberFunction, "@nogc"));
static assert(hasAttribute!(Aggregate.memberFunction, "@system"));

extern(C) int main()
{
    return 0;
}
