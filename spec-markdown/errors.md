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

## Library optional and result types

The standard library module `laserd.result` provides two general result
aggregates. `Optional` carries a value which may be absent. `Result` carries
either a value or an error, and its value type may be `void` for an operation
which produces no value when it succeeds.

```d
import laserd.result : Optional, Result;

enum ParseError
{
    invalidInput,
    outOfRange,
}

Result!(int, ParseError) parseInteger(const(char)[] text);

int useInteger(const(char)[] text, out int value)
{
    Result!(int, ParseError) result = parseInteger(text);
    if (!result.isOk())
        return cast(int) result.errorOr(ParseError.invalidInput);

    value = result.valueOr(0);
    return 0;
}
```

Both types are ordinary value types. `Result` stores its value and its error in
overlapping storage, which is well defined because no Laser-D type carries a
destructor, postblit, or copy or move constructor.

Every accessor is total. The language cannot require a caller to inspect a
result, so no accessor is undefined when the value is absent. `orElse`,
`valueOr`, and `errorOr` take a fallback, while `ptr`, `value`, and `error`
return `null` in the states which carry no data. A returned pointer refers into
the value it was taken from and is valid only while that value is alive and
unmodified.

`mapValue` and `mapValueContext` transform a successful value using an ordinary
function pointer. Context is passed explicitly because Laser-D has no capturing
delegates.

The representation is uniform for every element type. A pointer element does not
use `null` to represent absence, so a present `null` pointer remains
distinguishable from an absent value.

This module is one available convention. An API may use status values, output
parameters, or its own result aggregate instead.

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
