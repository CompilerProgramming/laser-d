// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/capturing_delegates_rejected.d(21): Error: capturing delegates are not supported in Laser-D
laser-d/capturing_delegates_rejected.d(20):        captured variable `captured` declared here
laser-d/capturing_delegates_rejected.d(26): Error: capturing delegates are not supported in Laser-D
laser-d/capturing_delegates_rejected.d(24):        captured variable `captured` declared here
---
*/

int invoke(int delegate(int) operation, int value)
{
    return operation(value);
}

void scopedCapture()
{
    int captured = 10;
    invoke((int value) => captured + value, 5);
}

int delegate(int) escapingCapture(int captured)
{
    return (int value) => captured + value;
}
