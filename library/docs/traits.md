# Compile-time traits: std.traits

`std.traits` provides compile-time type predicates, symbol inspection, and
type transformations. It is a reduced Phobos-compatible API with no public
structs or runtime functions, and it allocates no memory.

## Type and symbol inspection

| API | Meaning |
| --- | --- |
| `ReturnType!functionSymbol` | Function symbol's return type. |
| `Parameters!functionSymbol`, `ParameterTypeTuple` | Function parameter type sequence. |
| `arity!functionSymbol` | Number of parameters. |
| `Fields!T`, `FieldTypeTuple` | Field type sequence from `T.tupleof`. |
| `hasMember!(T, name)` | Whether a named member exists. |
| `hasElaborateDestructor!T` | Whether the frontend reports destruction is needed. |
| `mangledName!symbol` | Compiler-mangled symbol name. |

## Predicates

Each takes a type `T`, except where another parameter list is shown, and
produces a compile-time Boolean.

| Group | API |
| --- | --- |
| Numeric and scalar | `isBoolean`, `isIntegral`, `isFloatingPoint`, `isNumeric`, `isScalarType`, `isBasicType`, `isUnsigned`, `isSigned` |
| Characters and strings | `isSomeChar`, `isSomeString`, `isNarrowString` |
| Arrays and pointers | `isStaticArray`, `isDynamicArray`, `isArray`, `isAssociativeArray`, `isPointer` |
| Other type categories | `isAggregateType`, `isBuiltinType`, `isMutable` |
| Conversion | `isImplicitlyConvertible!(From, To)` |
| Template instance | `isInstanceOf!(Template, T)` |
| Callable symbols | `isFunctionPointer!symbol`, `isDelegate!symbol`, `isSomeFunction!symbol` |

`isSomeChar` recognizes `char`, `wchar`, and `dchar`; `isNarrowString` recognizes
character slices of `char` or `wchar`. These inspection predicates do not provide
text codecs. A predicate name such as `isAssociativeArray` or `isDelegate`
does not make the corresponding language feature available in Laser-D.

## Type transformations

| API | Result |
| --- | --- |
| `ConstOf!T`, `ImmutableOf!T` | Qualified type. |
| `PointerTarget!T` | Pointee type; requires a pointer type. |
| `KeyType!T`, `ValueType!T` | Associative-array key/value type patterns; built-in associative arrays remain rejected. |
| `Select!(condition, T, F)` | `T` when true, otherwise `F`. |

Function inspection takes a function symbol. Invalid arguments to
`ReturnType`/`Parameters` produce a compile-time error. Other Phobos facilities
are not implicitly available.

## Using the library

No native archive or runtime initialization is required.

## Implementation Details

Source: `library/std/traits.d`.

Integration coverage: `library/test/traits.d` (CTest `std_traits`).

The module is derived from Phobos and uses frontend type/symbol traits.
Deferred upstream groups remain listed in source comments as a review inventory.
