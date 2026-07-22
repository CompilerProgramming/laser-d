// TEST_MODE: compilable

int useParameters(in int input, out int output, ref int referenced)
{
    output = input;
    referenced += input;
    return referenced;
}
