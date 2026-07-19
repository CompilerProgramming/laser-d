// TEST_MODE: compilable

extern(C++)
{
    int cppFunction(int value);
    void overloaded(int value);
    void overloaded(double value);
}

alias FunctionType = extern(C++) int function(int);

static assert(is(typeof(&cppFunction) == FunctionType));
