// Every function type carries the mandatory Laser-D attributes.
void ordinary()
{
}

extern(C) void externalFunction();
void function() functionPointer;

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

extern(C) int main()
{
    return 0;
}
