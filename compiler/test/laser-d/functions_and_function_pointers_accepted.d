// TEST_MODE: runnable

int add(int left, int right)
{
    return left + right;
}

alias BinaryFunction = int function(int, int);
alias UnaryFunction = int function(int);

int invoke(BinaryFunction operation, int left, int right)
{
    return operation(left, right);
}

extern(C) int main()
{
    BinaryFunction operation = &add;
    if (invoke(operation, 20, 22) != 42)
        return 1;

    UnaryFunction twice = (int value) => value * 2;
    return twice(21) == 42 ? 0 : 2;
}
