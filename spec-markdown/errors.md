---
title: Error handling
status: restricted
source: ../spec/errors.dd
---

# Error handling

Laser-D represents failure as ordinary program data and propagates it through
ordinary control flow. The language does not prescribe one universal result
type: an API chooses a convention appropriate to its domain and foreign
interface.

Differences from D's error model are summarized in
[D compatibility notes](d-compatibility.md).

## Status values

A function may return an integer, enum, Boolean, pointer, or another supported
value that distinguishes success from failure. Callers test that result
explicitly.

```d
enum ReadStatus
{
    success,
    endOfInput,
    failure,
}

ReadStatus readValue(out int value);

int consumeValue()
{
    int value;
    ReadStatus status = readValue(value);
    if (status != ReadStatus.success)
        return cast(int) status;

    return value;
}
```

An `out` or `ref` parameter can carry a successful value when the function
result carries the status. The API must define whether output parameters are
meaningful after failure.

## Result aggregates

A struct may carry status and result data together. This is useful when the
caller must not confuse an error code with a valid result.

```d
enum ParseStatus
{
    success,
    invalidInput,
    outOfRange,
}

struct ParseResult
{
    ParseStatus status;
    int value;
}

ParseResult parseInteger(const(char)[] text);

int useInteger(const(char)[] text, out int value)
{
    ParseResult result = parseInteger(text);
    if (result.status != ParseStatus.success)
        return cast(int) result.status;

    value = result.value;
    return 0;
}
```

The status determines which fields contain meaningful data. No hidden
allocation, propagation, or cleanup is associated with a result aggregate.

## Propagation

Failure is propagated with visible conditions and returns. Each function
translates, handles, or forwards the status according to its own contract.

```d
int performStep();

int performOperation()
{
    int status = performStep();
    if (status != 0)
        return status;

    return 0;
}
```

This control flow is the same for native Laser-D functions and foreign
functions.

## C error conventions

An `extern(C)` declaration retains the convention defined by the C API. Common
conventions include:

- zero or nonzero integer status values;
- null pointers;
- sentinel values;
- output parameters; and
- a separate function or C runtime facility that supplies error details.

The binding must document which convention applies, which values are valid,
and how long any returned pointer or error text remains usable. Laser-D does
not automatically inspect or translate a foreign error indicator.

## Cleanup

`scope(exit)` releases resources acquired within a lexical scope. A guard is
normally registered immediately after successful acquisition.

```d
extern(C) int acquire();
extern(C) void release(int handle);
extern(C) int operate(int handle);

int useResource()
{
    int handle = acquire();
    if (handle < 0)
        return handle;

    scope(exit) release(handle);

    int status = operate(handle);
    if (status != 0)
        return status;

    return 0;
}
```

Active guards execute when ordinary control flow leaves their scopes. Cleanup
order and transfer behavior are specified in [Statements](statement.md).

## Compile-time validation

`static assert` validates compiler-known requirements and stops compilation
when its condition is false. It does not represent or handle a failure that
occurs while the program is running.
