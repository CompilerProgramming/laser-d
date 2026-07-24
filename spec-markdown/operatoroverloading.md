---
title: Operator overloading
status: restricted
source: ../spec/operatoroverloading.dd
---

# Operator overloading

Laser-D supports modern operator overloading on structs. An overloaded
operator is rewritten to an explicitly declared struct method or method
template.

Operator syntax is intended for value types whose operations have a clear
conventional meaning, such as numeric, matrix, fixed-storage, or iterator
types. The compiler validates declarations and performs overload resolution;
it does not judge whether an overload is intuitive.

Differences from D operator overloading are summarized in
[D compatibility notes](d-compatibility.md).

## Common rules

- A hook is an ordinary or templated struct method and follows the Laser-D
  rules for functions, parameters, results, qualifiers, and storage.
- Hook selection uses ordinary overload resolution and template constraint
  evaluation.
- Calling a hook directly uses explicit function-call parentheses.
- Built-in behavior is used when no struct operand requires an operator
  rewrite.
- Overloading does not change an operator's precedence or associativity.

## Unary operators

A unary operator on struct value `value` may call:

```d
value.opUnary!"operator"()
```

The operator token is supplied as an immutable compile-time string.

| Source | Rewrite |
| --- | --- |
| `-value` | `value.opUnary!"-"()` |
| `+value` | `value.opUnary!"+"()` |
| `~value` | `value.opUnary!"~"()` |
| `*value` | `value.opUnary!"*"()` |
| `++value` | `value.opUnary!"++"()` |
| `--value` | `value.opUnary!"--"()` |

A hook may specialize or constrain its token parameter.

### Postfix increment and decrement

`value++` and `value--` preserve an ordinary value copy and then apply the
corresponding prefix hook. The struct must be value-copyable.

## Binary operators

For `left op right`, overload resolution first considers:

```d
left.opBinary!"op"(right)
```

When that call is not viable and the right operand is a struct, overload
resolution considers:

```d
right.opBinaryRight!"op"(left)
```

The hook's parameters and result must use supported Laser-D types.

## Equality

`left == right` and `left != right` may call a viable `opEquals` method:

```d
bool opEquals(Other right);
```

The compiler negates the equality result for `!=`.

## Ordering

An `opCmp` hook returns a negative value, zero, or a positive value.
Relational operators compare that result with zero:

| Source | Meaning |
| --- | --- |
| `left < right` | `left.opCmp(right) < 0` |
| `left <= right` | `left.opCmp(right) <= 0` |
| `left > right` | `left.opCmp(right) > 0` |
| `left >= right` | `left.opCmp(right) >= 0` |

Programs should keep `opEquals` and `opCmp` logically consistent.

## Cast operators

An explicit cast may call a templated `opCast` hook:

```d
Target result = cast(Target) value;

Target opCast(Target)();
```

The target and result must be supported Laser-D types. An `opCast!bool` hook
provides the struct's Boolean conversion.

## Call operators

Calling a struct value calls its `opCall` method:

```d
value(arguments)
value.opCall(arguments)
```

The source call and the direct method call both contain parentheses.

## Assignment

Assignment to an existing struct value may call:

```d
destination.opAssign(source)
```

Initialization of a newly declared value remains initialization.

Compound assignment may call:

```d
destination.opOpAssign!"op"(source)
```

The hook performs the mutation directly.

## Indexing

An index read calls `opIndex` with the source indices:

```d
value[indices]
value.opIndex(indices)
```

`opIndex` returns a value. A returned slice is a non-owning view whose backing
storage must remain valid.

Dedicated hooks provide index mutation:

| Source | Rewrite |
| --- | --- |
| `value[indices] = replacement` | `value.opIndexAssign(replacement, indices)` |
| `value[indices] op= operand` | `value.opIndexOpAssign!"op"(operand, indices)` |
| `++value[indices]` | `value.opIndexUnary!"++"(indices)` |
| `-value[indices]` | `value.opIndexUnary!"-"(indices)` |

## Slicing and `$`

A one-dimensional slice may call:

```d
value.opSlice(lower, upper)
```

Slice assignment may call:

```d
value.opSliceAssign(replacement, lower, upper)
```

Any returned slice follows the normal non-owning slice rules.

Within an overloaded index or slice expression, `$` calls:

```d
value.opDollar()
```

The returned value participates in the surrounding index expression.

## Multidimensional indexing

For multidimensional indexing, each sliced dimension is lowered before the
final read or mutation hook:

- `opDollar!dimension()` supplies `$` for a dimension.
- `opSlice!dimension(lower, upper)` constructs a descriptor for a sliced
  dimension.
- `opIndex` receives the resulting scalar indices and slice descriptors.
- `opIndexAssign`, `opIndexOpAssign`, and `opIndexUnary` provide mutation and
  unary operations.

Dimension numbers are compile-time values. The container expression is
evaluated once. Storage and slice descriptors are ordinary supported Laser-D
values.

## `opDispatch`

A struct may use a templated `opDispatch` hook to handle an otherwise
unresolved member name:

```d
ReturnType opDispatch(immutable(char)[] name)(Arguments);
```

The member name is an immutable compile-time string. The selected member call
uses explicit parentheses.

## Immutable receivers

Operator hooks may be declared for an `immutable` receiver and invoked on
immutable struct values. Parameters and results may use supported `const` and
`immutable` types.
