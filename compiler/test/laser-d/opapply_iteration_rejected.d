// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/opapply_iteration_rejected.d(22): Error: `opApply` iteration is not supported in Laser-D; use a range or explicit loop
---
*/

struct Values
{
    int opApply(int delegate(int) visit)
    {
        return visit(1);
    }
}

extern(C) int main()
{
    int sum;
    Values values;
    foreach (value; values)
        sum += value;
    return sum;
}
