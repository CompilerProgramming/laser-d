// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/range_iteration_invalid_rejected.d(60): Error: Laser-D range method `badEmpty.empty` must return `bool`
laser-d/range_iteration_invalid_rejected.d(64): Error: Laser-D range `missingPopFront` requires a callable `popFront()` method
laser-d/range_iteration_invalid_rejected.d(68): Error: Laser-D range method `badFront.front` must return a non-`ref` value
laser-d/range_iteration_invalid_rejected.d(72): Error: Laser-D range method `badPopFront.popFront` must return `void`
laser-d/range_iteration_invalid_rejected.d(76): Error: Laser-D range method `badBack.back` must return a non-`ref` value
laser-d/range_iteration_invalid_rejected.d(80): Error: Laser-D range `missingPopBack` requires a callable `popBack()` method
---
*/

struct BadEmpty
{
    int empty() { return 0; }
    int front() { return 1; }
    void popFront() {}
}

struct MissingPopFront
{
    bool empty() { return true; }
    int front() { return 1; }
}

struct BadFront
{
    bool empty() { return true; }
    void front() {}
    void popFront() {}
}

struct BadPopFront
{
    bool empty() { return true; }
    int front() { return 1; }
    int popFront() { return 0; }
}

struct BadBack
{
    bool empty() { return true; }
    void back() {}
    void popBack() {}
}

struct MissingPopBack
{
    bool empty() { return true; }
    int back() { return 1; }
}

extern(C) int main()
{
    int sum;

    BadEmpty badEmpty;
    foreach (value; badEmpty)
        sum += value;

    MissingPopFront missingPopFront;
    foreach (value; missingPopFront)
        sum += value;

    BadFront badFront;
    foreach (value; badFront)
        sum += value;

    BadPopFront badPopFront;
    foreach (value; badPopFront)
        sum += value;

    BadBack badBack;
    foreach_reverse (value; badBack)
        sum += value;

    MissingPopBack missingPopBack;
    foreach_reverse (value; missingPopBack)
        sum += value;

    return sum;
}
