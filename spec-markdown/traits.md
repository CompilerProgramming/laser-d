---
title: Traits
status: restricted
source: ../spec/traits.dd
---

# Traits

> **Laser-D normative:**
>
> `__traits` provides compile-time inspection of supported
> Laser-D types, declarations, functions, parameters, symbols, layout, and target
> information. Trait evaluation does not execute runtime reflection, allocate
> storage, or require `TypeInfo`.

A predicate may ask whether an operand belongs to a rejected language
category. Such a query does not make that category available: it normally
returns false for valid Laser-D operands, and a trait requiring an actual
excluded operand has no valid Laser-D use.

## <a id="grammar"></a>Grammar

```text
TraitsExpression:
    __traits ( TraitsKeyword , TraitsArguments )

TraitsArguments:
    TraitsArgument
    TraitsArgument , TraitsArguments

TraitsArgument:
    AssignExpression
    Type
```

The accepted number and kind of arguments depend on the selected trait.
Trait names are compiler-defined identifiers, not ordinary functions or
templates.

## <a id="types"></a>Type and Layout Traits

### <a id="type-predicates"></a>Type Predicates

| Trait | Result |  |
| --- | --- | --- |
| `__traits(isArithmetic, operands)` | true when every operand has a supported arithmetic type |  |
| `__traits(isFloating, operands)` | true for supported floating-point types |  |
| `__traits(isIntegral, operands)` | true for supported integral and integral-based enum types |  |
| `__traits(isScalar, operands)` | true for supported scalar types | including pointers |
| `__traits(isUnsigned, operands)` | true for supported unsigned integral and unsigned-based enum types |  |
| `__traits(isStaticArray, operands)` | true for fixed-size array types |  |
| `__traits(isAssociativeArray, operands)` | reports whether an operand is an associative-array type |  |
| `__traits(isOverlapped, field)` | true when a field overlaps other aggregate storage |  |

Associative-array types are rejected, so
`__traits(isAssociativeArray, ...)` remains useful to generic code but
cannot receive a valid Laser-D associative-array operand. Similar predicates
never authorize rejected scalar, vector, class, or interface types.

### <a id="representation-predicates"></a>Representation Predicates

| Trait | Result |
| --- | --- |
| `__traits(isCopyable, T)` | whether values of `T` have ordinary copy semantics |
| `__traits(isPOD, T)` | whether `T` is plain data under the frontend's representation rules |
| `__traits(isZeroInit, T)` | whether all-zero storage is `T`'s default initializer |
| `__traits(hasCopyConstructor, T)` | whether `T` declares a copy constructor |
| `__traits(hasMoveConstructor, T)` | whether `T` declares a move constructor |
| `__traits(hasPostblit, T)` | whether `T` declares a postblit |
| `__traits(needsDestruction, T)` | whether `T` requires destruction |
| `__traits(getAliasThis, T)` | aliases introduced by `alias this` |

Copy constructors, move constructors, postblits, destructors, and
`alias this` are rejected. Their predicates remain available for generic
code and report their absence on conforming Laser-D aggregate types.

### <a id="bitfield-traits"></a>Bit-Field Traits

| Trait | Result |
| --- | --- |
| `__traits(isBitfield, field)` | whether the symbol is a bit field |
| `__traits(getBitfieldOffset, field)` | bit offset within its storage unit |
| `__traits(getBitfieldWidth, field)` | declared width in bits |

These traits inspect the target layout chosen for a supported bit field.
They do not change its width or storage.

### <a id="initSymbol"></a>Initialization Symbol

`__traits(initSymbol, T)` returns the compiler-generated initialization
symbol for a supported aggregate type when such a symbol exists. It exposes no
GC pointer map or runtime type metadata.

### <a id="class-only"></a>Class-Only Queries

The frontend recognizes `isAbstractClass`, `isFinalClass`, `isCOMClass`, `classInstanceSize`, `classInstanceAlignment`, `getVirtualFunctions`, and `getVirtualMethods`. Class declarations and
class types are rejected, so the size, alignment, and virtual-member queries
have no valid class operand in Laser-D. The predicate forms return false for
ordinary supported non-class operands.

## <a id="functions"></a>Function Traits

| Trait | Result |
| --- | --- |
| `__traits(isStaticFunction, symbol)` | whether a function requires no receiver |
| `__traits(isAbstractFunction, symbol)` | whether a function is abstract |
| `__traits(isVirtualFunction, symbol)` | whether a function is virtual |
| `__traits(isVirtualMethod, symbol)` | whether a member is a virtual method |
| `__traits(isFinalFunction, symbol)` | whether a function is final |
| `__traits(isOverrideFunction, symbol)` | whether a function overrides another |
| `__traits(getVirtualIndex, symbol)` | virtual-table index or a negative value when none exists |
| `__traits(isReturnOnStack, symbol)` | target-ABI decision for returning the function result indirectly |
| `__traits(getFunctionAttributes, symbol)` | compile-time sequence of the function's effective attributes |
| `__traits(getFunctionVariadicStyle, symbol)` | variadic style name |

Native Laser-D functions are non-virtual because classes and interfaces
are unavailable. The virtual and override predicates remain usable by generic
code but return false for valid ordinary functions and struct methods.

`getFunctionAttributes` includes effective implicit attributes such as
`nothrow` and `@nogc`. Their presence in the returned sequence does not
permit those rejected explicit annotations in source.

`getFunctionVariadicStyle` reports `"none"` for ordinary functions
and `"stdarg"` for supported C ABI variadics. Rejected D and typesafe
runtime-variadic declarations cannot be introduced merely to query them.

## <a id="function-parameters"></a>Variable and Parameter Traits

| Trait | Result |
| --- | --- |
| `__traits(isRef, symbol)` | whether the variable or parameter is declared `ref` |
| `__traits(isOut, symbol)` | whether the parameter is declared `out` |
| `__traits(isLazy, symbol)` | whether the parameter is declared `lazy` |
| `__traits(getParameterStorageClasses, function, index)` | compile-time sequence of storage-class names for the indexed parameter |
| `__traits(parameters)` | alias sequence of the current function's parameters |

`in`, `out`, and `ref` are the supported explicit parameter
annotations. `lazy`, `scope`, `return`, `inout`, and other rejected
annotations cannot be restored through inspection; their predicates or storage
class names are useful only when generic code examines a declaration that can
otherwise exist.

`__traits(parameters)` is valid in a function context and provides its
parameters in declaration order. It creates no runtime tuple.

## <a id="symbols"></a>Symbol Traits

### <a id="identity-and-kind"></a>and Kind

| Trait | Result |  |  |
| --- | --- | --- | --- |
| `__traits(identifier, symbol)` | unqualified identifier |  |  |
| `__traits(fullyQualifiedName, symbol)` | fully qualified compile-time name |  |  |
| `__traits(isTemplate, symbol)` | whether the symbol is a template declaration |  |  |
| `__traits(isModule, symbol)` | whether the symbol is a module |  |  |
| `__traits(isPackage, symbol)` | whether the symbol is a package |  |  |
| `__traits(isNested, symbol)` | whether the declaration has lexical nesting |  |  |
| `__traits(isFuture, symbol)` | whether the declaration carries D's future status |  |  |
| `__traits(isDeprecated, symbol)` | whether the declaration is deprecated |  |  |
| `__traits(isDisabled, symbol)` | whether the declaration is disabled |  |  |
| `__traits(isSame, left, right)` | whether both arguments denote the same type | symbol | or compile-time entity |

A kind predicate may report false for a supported operand when the queried
kind is excluded or unavailable. Inspection does not authorize declarations
whose attributes or forms are rejected elsewhere.

### <a id="members"></a>Members and Relationships

| Trait | Result |
| --- | --- |
| `__traits(hasMember, aggregate, name)` | whether the named member exists |
| `__traits(getMember, aggregate, name)` | the named member symbol or expression |
| `__traits(getOverloads, aggregate, name)` | overload sequence for the name |
| `__traits(allMembers, aggregate)` | compile-time sequence of all member names |
| `__traits(derivedMembers, aggregate)` | compile-time sequence of members introduced by the declaration |
| `__traits(parent, symbol)` | lexical parent |
| `__traits(child, parent, symbol)` | the child symbol rebound through the supplied parent value or scope |

Member sequences and overload sets are compile-time entities. Calling a
returned function or accessing a returned field must still use valid explicit
Laser-D syntax and satisfy receiver rules.

### <a id="declaration-metadata"></a>Declaration Metadata

| Trait | Result |  |  |
| --- | --- | --- | --- |
| `__traits(getAttributes, symbol)` | user-defined attribute sequence |  |  |
| `__traits(getLinkage, symbol)` | linkage name |  |  |
| `__traits(getLocation, symbol)` | source filename | line | and column |
| `__traits(getCppNamespaces, symbol)` | C++ namespace sequence |  |  |
| `__traits(getVisibility, symbol)` | visibility name |  |  |
| `__traits(getProtection, symbol)` | protection name |  |  |
| `__traits(getTargetInfo, key)` | compiler target information selected by the key |  |  |

Laser-D source declarations cannot carry user-defined attributes, so
`getAttributes` returns an empty sequence for them. C implementation
attributes in ImportC input remain governed by the ImportC rules.

Linkage, visibility, protection, C++ namespaces, and target information
report frontend or target facts. A returned value does not expand the set of
source features or create a cross-platform guarantee beyond the applicable
Laser-D ABI and interoperability specifications.

## <a id="semantic-probes"></a>Semantic Probes

### <a id="compiles"></a>`__traits(compiles)`

`__traits(compiles, arguments)` semantically checks its arguments in a
gagged compile-time context. It returns true only if all arguments are valid
Laser-D; otherwise it returns false without making the rejected construct part
of the program.

```d
struct Record
{
    int value;
}

static assert(__traits(compiles, Record.init.value));
static assert(!__traits(compiles, Record.init.missing));
```

This trait supports feature detection in templates. It does not suppress a
diagnostic when the same rejected construct is instantiated or used outside
the probe.

### <a id="isSame"></a>`__traits(isSame)`

`__traits(isSame, left, right)` tests compile-time identity rather than
runtime equality. It is supported for valid types, symbols, aliases, and other
accepted operands.

## <a id="excluded"></a>Excluded Traits

### <a id="toType"></a>`__traits(toType)` (Excluded)

> **Excluded from Laser-D:**
>
> `__traits(toType)` is rejected because it constructs a
> type from textual or mangled input. It would reintroduce a string-to-language
> generation boundary analogous to rejected string mixins.

### <a id="getPointerBitmap"></a>`__traits(getPointerBitmap)` (Excluded)

> **Excluded from Laser-D:**
>
> `__traits(getPointerBitmap)` is rejected because Laser-D
> has no garbage collector or GC scanning-metadata contract.

### <a id="getUnitTests"></a>`__traits(getUnitTests)` (Excluded)

> **Excluded from Laser-D:**
>
> `__traits(getUnitTests)` is rejected because Laser-D has
> no language `unittest` declarations or hidden test-function discovery
> protocol.

## <a id="restrictions"></a>Reflection Boundary

Traits inspect compiler-known information; they do not provide runtime
reflection. A trait cannot allocate, read a file, discover runtime classes, invoke a hidden lifecycle function, or bypass a parser or semantic diagnostic.

Results may be used by supported templates, constraints, `static if`, `static foreach`, `static assert`, and CTFE. Any declaration selected or
generated through that compile-time control flow remains subject to all
Laser-D restrictions.
