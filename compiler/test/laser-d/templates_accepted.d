// TEST_MODE: compilable

template Identity(T)
{
    alias Identity = T;
}

template Constant(T, T value)
{
    enum Constant = value;
}

template Factorial(uint value)
{
    enum Factorial = value * Factorial!(value - 1);
}

template Factorial(uint value : 0)
{
    enum Factorial = 1;
}

template TypeSequence(Types...)
{
    alias TypeSequence = Types;
}

alias Pointer(T) = T*;
enum doubled(int value) = value * 2;

T maximum(T)(T left, T right)
    if (is(T == int) || is(T == long))
{
    return left > right ? left : right;
}

struct Pair(First, Second = First)
{
    First first;
    Second second;
}

static assert(is(Identity!int == int));
static assert(Constant!(int, 42) == 42);
static assert(Factorial!5 == 120);
static assert(TypeSequence!(int, long, char).length == 3);
static assert(is(Pointer!int == int*));
static assert(doubled!21 == 42);
static assert(maximum(10, 20) == 20);
static assert(is(typeof(Pair!(int, long).first) == int));
static assert(is(typeof(Pair!int.second) == int));
