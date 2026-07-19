// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/capturing_delegates_rejected.d(23): Error: capturing delegates are not supported in Laser-D
laser-d/capturing_delegates_rejected.d(22):        captured variable `captured` declared here
laser-d/capturing_delegates_rejected.d(28): Error: capturing delegates are not supported in Laser-D
laser-d/capturing_delegates_rejected.d(26):        captured variable `captured` declared here
laser-d/capturing_delegates_rejected.d(34): Error: capturing delegates are not supported in Laser-D
laser-d/capturing_delegates_rejected.d(33):        captured variable `captured` declared here
---
*/

int invoke(scope int delegate(int) operation, int value)
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

int delegate(int) namedCapture()
{
    int captured = 30;
    int nested(int value)
    {
        return captured + value;
    }
    return &nested;
}
