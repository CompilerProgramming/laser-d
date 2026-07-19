// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/threading_and_purity_rejected.d(12): Error: `shared` is not supported in Laser-D because native multithreading is disabled
laser-d/threading_and_purity_rejected.d(14): Error: `pure` is not supported in Laser-D; functions remain conservatively impure for C interoperability
laser-d/threading_and_purity_rejected.d(21): Error: `synchronized` is not supported in Laser-D because native synchronization is disabled
---
*/

alias SharedInteger = shared(int);

int pureFunction() pure
{
    return 1;
}

void synchronizedFunction()
{
    synchronized
    {
    }
}
