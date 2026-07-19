// TEST_MODE: runnable

struct Pair
{
    int first;
    int second;
};

union Word
{
    unsigned int whole;
    unsigned short half;
};

enum Colour
{
    red = 1,
    green = 2
};

typedef int (*binary_function)(int, int);

static int add(int left, int right)
{
    return left + right;
}

_Static_assert(sizeof(struct Pair) == 2 * sizeof(int), "unexpected Pair layout");

int main(void)
{
    struct Pair pair = { 20, 22 };
    union Word word = { 42u };
    binary_function operation = add;

    if (pair.first + pair.second != 42)
        return 1;
    if (word.whole != 42u)
        return 2;
    if (green != 2)
        return 3;
    return operation(19, 23) == 42 ? 0 : 4;
}
