// TEST_MODE: compilable

struct Record
{
    int value;

    int method(int input)
    {
        return value + input;
    }
}

template Generic(T)
{
    alias Generic = T;
}

extern(C) int cFunction(int value);

int overloaded(int value)
{
    return value;
}

long overloaded(long value)
{
    return value;
}

static assert(__traits(identifier, Record) == "Record");
static assert(__traits(identifier, Record.value) == "value");
static assert(__traits(fullyQualifiedName, Record) == "traits_symbol_accepted.Record");
static assert(__traits(isTemplate, Generic));
static assert(__traits(isModule, __traits(parent, Record)));
static assert(!__traits(isPackage, Record));
static assert(!__traits(isNested, Record));
static assert(!__traits(isDeprecated, Record));
static assert(!__traits(isDisabled, Record));

static assert(__traits(hasMember, Record, "value"));
static assert(!__traits(hasMember, Record, "missing"));
static assert(__traits(isSame, __traits(getMember, Record, "value"), Record.value));
static assert(__traits(getOverloads, Record, "method").length == 1);
static assert(__traits(getOverloads, traits_symbol_accepted, "overloaded").length == 2);
static assert(__traits(allMembers, Record).length >= 2);
static assert(__traits(derivedMembers, Record).length >= 2);
static assert(__traits(getAttributes, Record).length == 0);
static assert(__traits(getLinkage, cFunction) == "C");
static assert(__traits(getProtection, Record) == "public");
static assert(__traits(getVisibility, Record) == "public");
static assert(__traits(getLocation, Record).length == 3);
static assert(__traits(getCppNamespaces, cFunction).length == 0);
static assert(is(typeof(__traits(getTargetInfo, "objectFormat")) : immutable(char)[]));

static assert(__traits(compiles, Record.init.value));
static assert(!__traits(compiles, Record.init.missing));
static assert(__traits(isSame, Record, Record));
static assert(!__traits(isSame, Record, int));
