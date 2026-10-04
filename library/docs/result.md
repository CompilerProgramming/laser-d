# Optional and result values: laserd.result

Source: `library/laserd/result.d`. No native archive or initialization is required.

`laserd.result` provides the pure Laser-D value types `Optional` and `Result`.
Laser-D has no exceptions, because D's exception hierarchy is built on classes,
so a fallible operation reports failure as ordinary returned data. `Optional`
carries a value which may be absent; `Result` carries either a value or an
error, and its value type may be `void` for operations which produce no value
on success. Both are plain value types with no allocation, runtime metadata, or
hidden control flow. A `Result` stores its value and error in overlapping
storage, which is sound because Laser-D rejects destructors, postblits, and
copy or move constructors, so no member carries lifecycle behaviour.

Every accessor is total. The language cannot require a caller to inspect a
result: `@disable` is rejected, so construction cannot be routed through a
checked path, and destructors are rejected, so an ignored value cannot be
detected when it goes out of scope. The module therefore has no operation which
is undefined on the absent side. A caller supplies a fallback with `orElse`,
`valueOr`, or `errorOr`, or takes a pointer accessor which is `null` in the
states carrying no data. Pointer accessors refer into the value they were taken
from and do not outlive it. `mapValue` and `mapValueContext` transform a
successful value through an ordinary function pointer, with context passed
explicitly because Laser-D has no capturing delegates. The representation is
uniform for every element type; a pointer element deliberately does not use
`null` as its empty representation, since a Laser-D pointer is nullable and a
present `null` would otherwise be indistinguishable from an absent value.

## Optional(T)

Default initialization produces an absent value. Its storage is private.

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

Default initialization produces an error containing `E.init`. Storage is
private. The common API is:

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

Integration coverage: `library/test/result.d` (CTest `result`).
