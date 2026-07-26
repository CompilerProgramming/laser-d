// TEST_MODE: compilable

V reduce(alias fun, V, R)(V x, R range)
    if (is(typeof(x = fun(x, range.front())))
        && is(typeof(range.empty()) == bool)
        && is(typeof(range.popFront()) == void))
{
    for (; !range.empty(); range.popFront()) {
        x = fun(x, range.front());
    }
    return x;
}

struct SliceRange(T)
{
    T[] remaining;

    this(T[] values)
    {
        remaining = values;
    }

    bool empty()
    {
        return remaining.length == 0;
    }

    T front()
    {
        return remaining[0];
    }

    void popFront()
    {
        remaining = remaining[1 .. $];
    }
}

void test()
{
    int[5] r = [ 10, 14, 3, 5, 23 ];

    auto rr = SliceRange!int(r[]);

    // Compute the sum of all elements
    int sum = reduce!((a,b) { return a + b; })(0, rr);
    // assert(sum == 55);
    // Compute minimum
    int min = reduce!((a,b) { return a < b ? a : b; })(r[0],rr);
    // assert(min == 3)
}