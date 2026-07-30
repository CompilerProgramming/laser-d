// TEST_MODE: runnable
// REQUIRED_ARGS: -release -check=assert=off -checkaction=halt

private bool evaluatedTrue(int* evaluations)
{
    ++*evaluations;
    return true;
}

extern(C) int main()
{
    int evaluations;
    assert(evaluatedTrue(&evaluations), "assert must remain enabled");
    return evaluations == 1 ? 0 : 1;
}
