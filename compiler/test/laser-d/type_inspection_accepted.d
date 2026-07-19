// TEST_MODE: compilable

struct Record
{
    int value;
}

union Storage
{
    int signedValue;
    uint unsignedValue;
}

enum Choice : ushort
{
    first,
    second,
}

alias FunctionType = int function(int);
alias DelegateType = int delegate(int);

int inspectReturnType()
{
    typeof(return) result = 42;
    return result;
}

int proveTypeofDoesNotEvaluate()
{
    int value;
    typeof(++value) anotherValue;
    return value;
}

static assert(is(typeof(1 + 2) == int));
static assert(is(typeof(1 + 2.0) == double));
static assert(is(typeof(null)));
static assert(typeof(int.init).sizeof == int.sizeof);
static assert(is(typeof(Record.value) == int));
static assert(inspectReturnType() == 42);
static assert(proveTypeofDoesNotEvaluate() == 0);

static assert(is(int));
static assert(is(int == int));
static assert(is(int : long));
static assert(!is(int == uint));
static assert(is(Record == struct));
static assert(is(Storage == union));
static assert(is(Choice == enum));
static assert(is(FunctionType));
static assert(is(DelegateType));
static assert(!is(UndefinedType));

static if (is(int* PointerType : PointerType*))
    static assert(is(PointerType == int));
else
    static assert(false);
