// TEST_MODE: runnable

private bool evaluatedTrue(int* evaluations)
{
    ++*evaluations;
    return true;
}

private int ctfeChecked(int value)
{
    assert(value > 0);
    return value;
}

enum ctfeValue = ctfeChecked(7);
static assert(ctfeValue == 7);

private void unconditionalFailure()
{
    assert(0);
}

extern(C) int main()
{
    int evaluations;
    assert(evaluatedTrue(&evaluations));
    assert(evaluations == 1, "assert condition must execute exactly once");
    return evaluations == 1 ? 0 : 1;
}
