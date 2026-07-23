---
title: Operator overloading
status: restricted
source: ../spec/operatoroverloading.dd
---

# Operator Overloading

> **Laser-D normative:**
>
> Laser-D supports modern operator overloading on structs.
> An overloaded operator is rewritten to an explicitly declared struct method or
> method template. The rewrite does not add allocation, ownership, runtime type
> metadata, virtual dispatch, or a hidden object model.

Operator syntax is intended for value types whose operations have a clear
conventional meaning, such as numeric, matrix, fixed-storage, or iterator
types. The compiler enforces the hook signatures and the general Laser-D
language restrictions; it does not judge whether an overload is intuitive.

## <a id="common-rules"></a>Common Rules

- Only supported struct types participate. Classes and interfaces are unavailable.
- A hook is an ordinary or templated method and must obey all Laser-D type, parameter, result, attribute, purity, and storage rules.
- Hook calls use normal overload resolution and template constraint evaluation.
- Explicit function-call parentheses remain mandatory when a hook or other method is called directly.
- Built-in behavior is used when no aggregate operand requires an operator rewrite.
- Operator overloading does not change precedence, associativity, or operand evaluation order.

## <a id="Unary"></a>Unary Operators

A supported unary operator on a struct value *value* is rewritten to
`value.opUnary!"operator"()`.

| Source | Rewrite |
| --- | --- |
| `-value` | `value.opUnary!"-"()` |
| `+value` | `value.opUnary!"+"()` |
| `~value` | `value.opUnary!"~"()` |
| `*value` | `value.opUnary!"*"()` |
| `++value` | `value.opUnary!"++"()` |
| `--value` | `value.opUnary!"--"()` |

The operator token is an immutable compile-time string template argument.
A hook may specialize or constrain that argument.

### <a id="postfix"></a>Postfix Increment and Decrement

Postfix `value++` and `value--` preserve the value before applying
the corresponding prefix hook. The struct must therefore be ordinarily
copyable under the Laser-D struct rules. No postblit, copy constructor, move
constructor, or destructor is invoked.

## <a id="Binary"></a>Binary Operators

For a binary expression `left op right`, overload resolution first
considers `left.opBinary!"op"(right)`. If that is not viable and the right
operand is a struct, it considers
`right.opBinaryRight!"op"(left)`.

Modern binary hooks may represent arithmetic, bitwise, shift, concatenation-token, exponentiation, or membership-token operations when their
parameter and result types are otherwise supported. A hook using `"~"` does
not enable built-in GC-backed array concatenation.

## <a id="eqcmp"></a>Equality and Ordering

### <a id="equals"></a>Equality

`left == right` and `left != right` use a viable
`opEquals` method. If no custom equality hook is present, supported structs
use field-wise equality. An equality hook returns `bool`.

### <a id="compare"></a>Ordering

`opCmp` returns a negative value, zero, or a positive value. Relational
operators compare that result with zero:

| Source | Meaning |
| --- | --- |
| `left < right` | `left.opCmp(right) < 0` |
| `left <= right` | `left.opCmp(right) <= 0` |
| `left > right` | `left.opCmp(right) > 0` |
| `left >= right` | `left.opCmp(right) >= 0` |

Reverse dispatch may be selected by ordinary overload resolution when the
left-hand call is not viable. Programs should keep `opEquals` and
`opCmp` logically consistent; the compiler does not prove that relationship.

## <a id="Cast"></a>Cast Operators

An explicit `cast(Target) value` may call
`value.opCast!Target()`. The target and result must be supported Laser-D
types. Boolean conversion through `opCast!bool` may be used where a Boolean
condition is required.

A cast hook cannot introduce a rejected class, associative-array, vector, `real`, imaginary, complex, qualified, or other excluded type.

## <a id="FunctionCall"></a>Call Operators

`value(arguments)` calls `value.opCall(arguments)`. The source call
must contain parentheses, including when there are no arguments.

Call operators do not make optional-parentheses property syntax available.
They are ordinary explicit calls after the operator rewrite.

## <a id="Assignment"></a>Assignment

Assignment to an existing struct may call
`destination.opAssign(source)` when the hook is viable. Initialization of a
new variable remains initialization and does not call `opAssign`.

## <a id="OpAssign"></a>Compound Assignment

`destination op= source` may call
`destination.opOpAssign!"op"(source)`. The hook performs the mutation; it
must not rely on a reference return.

## <a id="ArrayOps"></a>Indexing and Slicing

### <a id="Array"></a>Index Reads

`value[indices]` calls `value.opIndex(indices)`. Laser-D requires
`opIndex` to return by value. Returning a slice is permitted only as a
non-owning view whose backing storage remains valid.

### <a id="index-assignment"></a>Index Assignment

| Source | Rewrite |
| --- | --- |
| `value[indices] = replacement` | `value.opIndexAssign(replacement, indices)` |
| `value[indices] op= operand` | `value.opIndexOpAssign!"op"(operand, indices)` |
| `++value[indices]` | `value.opIndexUnary!"++"(indices)` |
| `-value[indices]` | `value.opIndexUnary!"-"(indices)` |

Index mutation uses these dedicated hooks instead of assigning through a
reference returned by `opIndex`. This preserves Laser-D's rejection of
reference return values.

### <a id="Slice"></a>Slicing

A one-dimensional slice `value[lower .. upper]` may call
`value.opSlice(lower, upper)` to construct a slice descriptor, followed by
the applicable read or mutation hook. A full slice may use the corresponding
parameterless form.

The directly supported one-dimensional slice-assignment hook is
`value.opSliceAssign(replacement, lower, upper)`. Any slice returned to the
program remains subject to the ordinary non-owning slice rules.

### <a id="dollar"></a>Dollar

Within an overloaded index or slice expression, `$` calls
`value.opDollar()`. Its result is used only as an ordinary value in the
surrounding index expression.

## <a id="multidimensional"></a>Multidimensional Indexing

> **Laser-D normative:**
>
> Modern multidimensional indexing and slicing are supported.
> Each sliced dimension lowers independently before the final read or mutation
> hook is called.

- `opDollar!dimension()` supplies `$` for a dimension.
- `opSlice!dimension(lower, upper)` constructs that dimension's slice descriptor.
- `opIndex` receives the resulting mixture of scalar indices and slice descriptors.
- `opIndexAssign`, `opIndexOpAssign`, and `opIndexUnary` provide the corresponding mutations and unary operations.

The container expression is evaluated once. Dimension numbers are
compile-time values. These rewrites do not create multidimensional
GC-managed arrays; storage and descriptors must use supported Laser-D types.

## <a id="opdispatch"></a>`opDispatch`

A struct may use the templated `opDispatch` hook to handle an otherwise
unresolved member name. The name is supplied as an immutable compile-time
string, and the selected hook is called with explicit parentheses.

`opDispatch` cannot restore property calls without parentheses, string
mixins, runtime reflection, or members whose declarations use rejected
features.

## <a id="immutable-receivers"></a>Immutable Receivers

Operator hooks may be declared for an `immutable` receiver and invoked
on immutable struct values. Parameters may use supported `const` or
`immutable` types. Postfix `const` receiver qualifiers and all `inout`
qualifiers remain unavailable.

## <a id="restrictions"></a>Cross-Cutting Restrictions

> **Excluded from Laser-D:** Operator hooks cannot use or implicitly restore:

- classes, interfaces, inheritance, or virtual dispatch,
- reference return values,
- postfix `const`, `inout`, `shared`, or rejected function annotations,
- postblits, copy or move constructors, destructors, or hidden contexts,
- GC-backed allocation, array growth, associative arrays, or capturing delegates,
- optional call parentheses or `@property`.

## <a id="Old-Style"></a>Legacy D1 Hooks (Excluded)

> **Excluded from Laser-D:**
>
> Legacy D1 operator hook names are rejected on aggregate
> instance methods. This includes the old unary, binary, reverse-binary, membership, concatenation, dereference, postfix, and compound-assignment hook
> families such as `opNeg`, `opAdd`, `opAdd_r`, `opIn_r`, `opCat`, `opStar`, `opPostInc`, and `opAddAssign`.

Use the modern `opUnary`, `opBinary`, `opBinaryRight`, and
`opOpAssign` templates and the modern indexing hooks described above.
