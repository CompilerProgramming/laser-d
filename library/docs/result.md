# Optional and result values: laserd.result

`laserd.result` provides `Optional!T` for a value that may be absent and
`Result!(T, E)` for a value or an error. `Result!(void, E)` represents operations
that succeed without producing a value. Neither type allocates memory.

Accessors return a caller-supplied fallback or a null pointer when the requested
value is absent. A present null pointer remains distinct from an absent value.
Pointers returned by accessors are borrowed and remain valid only while the
originating value is alive and unmodified.

## Optional(T)

Default initialization produces an absent value.

```d
struct Optional(T)
{
    static Optional some(T value);
    static Optional none();
    bool has();
    bool opCast(C : bool)();
    T orElse(T fallback);
    T* ptr();
}
```

`some` creates a present value, including a present null pointer. `none` creates
an absent value. `has` and conversion to `bool` test presence. `orElse` returns
the value or its fallback; `ptr` returns an interior pointer or null.

## Result(T, E)

Default initialization produces an error containing `E.init`. The common API is:

```d
struct Result(T, E)
{
    static Result err(E error);
    bool isOk();
    bool opCast(C : bool)();
    E errorOr(E fallback);
    E* error();
}
```

`err` creates a failure. `isOk` and conversion to `bool` test success.
`errorOr` returns the error or its fallback; `error` returns an interior pointer
on failure and null on success.

For non-void `T`, these additional members are available:

```d
static Result ok(T value);
T valueOr(T fallback);
T* value();
Result!(U, E) mapValue(U)(U function(T) transform);
Result!(U, E) mapValueContext(U)(void* context, U function(void*, T) transform);
```

`ok` creates a success. `valueOr` and `value` mirror the error accessors.
Mapping invokes the callback only on success, otherwise preserving the error.
For `T == void`, only `static Result ok()` replaces this group; there is no
value accessor or mapping member. Interior pointers remain valid only while
their originating value is alive and unmodified.

## Using the library

No native archive or initialization is required.

## Implementation Details

Source: `library/laserd/result.d`.

Integration coverage: `library/test/result.d` (CTest `result`).

`Result` stores its value and error in overlapping storage. Laser-D rejects
destructors, postblits, and copy or move constructors, so members do not carry
lifecycle behavior. Representation is uniform across element types; null is
not used as the empty-state representation for pointer elements.

The API uses ordinary returned data because Laser-D has no exceptions. The
language cannot require inspection of a result: `@disable` and destructors are
rejected. Total accessors provide defined fallback behavior instead. Mapping
uses ordinary function pointers and explicit context because capturing
delegates are unavailable. No runtime metadata or hidden control flow is used.
