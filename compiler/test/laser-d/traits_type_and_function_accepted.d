// TEST_MODE: compilable

struct Plain
{
    int value;
}

union Overlap
{
    int signedValue;
    uint unsignedValue;
}

int ordinary(int value)
{
    static assert(typeof(__traits(parameters)).length == 1);
    return value;
}

Plain returnPlain()
{
    return Plain.init;
}

static assert(__traits(isArithmetic, int));
static assert(__traits(isArithmetic, double));
static assert(__traits(isFloating, double));
static assert(__traits(isIntegral, int));
static assert(__traits(isScalar, int*));
static assert(__traits(isUnsigned, uint));
static assert(__traits(isStaticArray, int[4]));
static assert(!__traits(isAssociativeArray, int[4]));
static assert(__traits(isOverlapped, Overlap.signedValue));
static assert(!__traits(isAbstractClass, Plain));
static assert(!__traits(isFinalClass, Plain));
static assert(!__traits(isCOMClass, Plain));

static assert(__traits(isCopyable, Plain));
static assert(__traits(isPOD, Plain));
static assert(__traits(isZeroInit, Plain));
static assert(!__traits(hasCopyConstructor, Plain));
static assert(!__traits(hasMoveConstructor, Plain));
static assert(!__traits(hasPostblit, Plain));
static assert(!__traits(needsDestruction, Plain));
static assert(__traits(getAliasThis, Plain).length == 0);
static assert(__traits(compiles, __traits(initSymbol, Plain)));

static assert(!__traits(isAbstractFunction, ordinary));
static assert(!__traits(isVirtualMethod, ordinary));
static assert(!__traits(isFinalFunction, ordinary));
static assert(!__traits(isOverrideFunction, ordinary));
static assert(__traits(isStaticFunction, ordinary));
static assert(__traits(getVirtualIndex, ordinary) < 0);
static assert(is(typeof(__traits(isReturnOnStack, returnPlain)) == bool));
static assert(__traits(getFunctionAttributes, ordinary).length >= 2);
static assert(__traits(getFunctionVariadicStyle, ordinary) == "none");
static assert(__traits(getParameterStorageClasses, ordinary, 0).length == 0);

void inspectParameter(ref int value)
{
    static assert(__traits(isRef, value));
    static assert(!__traits(isOut, value));
    static assert(!__traits(isLazy, value));
}
