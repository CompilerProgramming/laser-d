// TEST_MODE: runnable

// `scope(exit)` is Laser-D's only cleanup construct, and its ordering and
// activation rules are runtime guarantees. scope_exit_accepted.d checks a
// guard through compile-time evaluation only, which exercises a different
// lowering path from generated code, so these cases run the guards instead.

struct Trace
{
    int[16] entries;
    int count;
}

void record(ref Trace trace, int identifier)
{
    trace.entries[trace.count] = identifier;
    ++trace.count;
}

// Multiple guards in one scope run in last-in, first-out order.
void lastInFirstOut(ref Trace trace)
{
    scope(exit) record(trace, 1);
    scope(exit) record(trace, 2);
    scope(exit) record(trace, 3);
}

// A guard becomes active only when execution reaches it, so a transfer taken
// beforehand does not run it.
void activationOnReach(ref Trace trace, bool leaveEarly)
{
    scope(exit) record(trace, 1);
    if (leaveEarly)
        return;
    scope(exit) record(trace, 2);
}

// A guard in a scope being left runs before a `goto case` or `goto default`
// transfer.
void switchTransfers(ref Trace trace, int selector)
{
    switch (selector)
    {
        case 0:
        {
            scope(exit) record(trace, 10);
            goto case 1;
        }

        case 1:
        {
            scope(exit) record(trace, 11);
            goto default;
        }

        default:
            record(trace, 12);
            break;
    }
}

// Guards nested in inner scopes run as each scope is left.
void nestedScopes(ref Trace trace)
{
    scope(exit) record(trace, 1);
    {
        scope(exit) record(trace, 2);
        {
            scope(exit) record(trace, 3);
        }
        record(trace, 4);
    }
    record(trace, 5);
}

bool matches(ref Trace trace, const(int)[] expected)
{
    if (trace.count != cast(int) expected.length)
        return false;
    for (int index; index < trace.count; ++index)
        if (trace.entries[index] != expected[index])
            return false;
    return true;
}

extern(C) int main()
{
    Trace lifo;
    lastInFirstOut(lifo);
    immutable int[3] lifoExpected = [3, 2, 1];
    if (!matches(lifo, lifoExpected[]))
        return 1;

    Trace early;
    activationOnReach(early, true);
    immutable int[1] earlyExpected = [1];
    if (!matches(early, earlyExpected[]))
        return 2;

    Trace complete;
    activationOnReach(complete, false);
    immutable int[2] completeExpected = [2, 1];
    if (!matches(complete, completeExpected[]))
        return 3;

    Trace transfers;
    switchTransfers(transfers, 0);
    immutable int[3] transfersExpected = [10, 11, 12];
    if (!matches(transfers, transfersExpected[]))
        return 4;

    Trace nested;
    nestedScopes(nested);
    immutable int[5] nestedExpected = [3, 4, 2, 5, 1];
    if (!matches(nested, nestedExpected[]))
        return 5;

    return 0;
}
