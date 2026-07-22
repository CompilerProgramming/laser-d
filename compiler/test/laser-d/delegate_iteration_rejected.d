// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/delegate_iteration_rejected.d(22): Error: delegate iteration is not supported in Laser-D; call the delegate explicitly
---
*/

int visitValues(int delegate(int) visit)
{
    if (visit(1))
        return 1;
    return visit(2);
}

extern(C) int main()
{
    int sum;
    int delegate(int delegate(int)) values =
        (int delegate(int) visit) => visitValues(visit);
    foreach (value; values)
        sum += value;
    return sum;
}
