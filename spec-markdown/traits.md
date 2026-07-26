---
title: Traits
status: restricted
source: ../spec/traits.dd
---

# Traits

`__traits` provides compile-time inspection of Laser-D types, declarations,
functions, parameters, symbols, layout, and target information.

Differences from D traits are summarized in
[D compatibility notes](d-compatibility.md). Trait operations awaiting review
are listed in [Feature status](../FEATURE_STATUS.md).

## Syntax

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

The number and kind of arguments depend on the trait. Trait names are
compiler-defined identifiers.

## Type predicates

| Trait | Result |
| --- | --- |
| `isArithmetic` | whether every operand has an arithmetic type |
| `isFloating` | whether every operand has a floating-point type |
| `isIntegral` | whether every operand has an integral or integral-based enum type |
| `isScalar` | whether every operand has a scalar type |
| `isUnsigned` | whether every operand has an unsigned integral or unsigned-based enum type |
| `isStaticArray` | whether every operand is a fixed-array type |
| `isAssociativeArray` | whether every operand is an associative-array type |
| `isOverlapped` | whether a field overlaps other aggregate storage |

Predicates return `bool` and are suitable for constraints and `static if`.

## Representation predicates

| Trait | Result |
| --- | --- |
| `isCopyable` | whether values have ordinary copy semantics |
| `isPOD` | whether a type is plain data under the representation rules |
| `isZeroInit` | whether all-zero storage is the default initializer |
| `hasCopyConstructor` | whether a type declares a copy constructor |
| `hasMoveConstructor` | whether a type declares a move constructor |
| `hasPostblit` | whether a type declares a postblit |
| `needsDestruction` | whether a type requires destruction |
| `getAliasThis` | sequence of aliases introduced by `alias this` |

These operations report compiler-known facts about their operands.

## Bit-field traits

| Trait | Result |
| --- | --- |
| `isBitfield` | whether a symbol is a bit field |
| `getBitfieldOffset` | bit offset within its storage unit |
| `getBitfieldWidth` | declared width in bits |

The offset and width describe the target layout chosen for the field.

## Initialization symbol

`__traits(initSymbol, T)` returns the compiler-generated initialization symbol
for an aggregate type when such a symbol exists.

## Function traits

| Trait | Result |
| --- | --- |
| `isStaticFunction` | whether a function requires no receiver |
| `isAbstractFunction` | whether a function is abstract |
| `isVirtualFunction` | whether a function is virtual |
| `isVirtualMethod` | whether a member is a virtual method |
| `isFinalFunction` | whether a function is final |
| `isOverrideFunction` | whether a function overrides another |
| `getVirtualIndex` | virtual-table index, or a negative value when there is none |
| `isReturnOnStack` | target-ABI decision for indirect result return |
| `getFunctionAttributes` | sequence of effective function attributes |
| `getFunctionVariadicStyle` | variadic-style name |

`getFunctionAttributes` includes effective implicit attributes. For ordinary
functions `getFunctionVariadicStyle` returns `"none"`; for C ABI variadic
functions it returns `"stdarg"`.

On Laser-D's supported x86-64 targets, `isReturnOnStack` is false for a
function returning `int` and true for a function returning a struct containing
ten `int` elements. These results expose the existing target ABI; they do not
select a different calling convention.

## Variable and parameter traits

| Trait | Result |
| --- | --- |
| `isRef` | whether a variable or parameter is `ref` |
| `isOut` | whether a parameter is `out` |
| `isLazy` | whether a parameter is `lazy` |
| `getParameterStorageClasses` | storage-class names for an indexed parameter |
| `parameters` | alias sequence of the current function's parameters |

`__traits(parameters)` is used within a function and lists its parameters in
declaration order. The result is a compile-time sequence.

## Symbol identity and kind

| Trait | Result |
| --- | --- |
| `identifier` | unqualified identifier |
| `fullyQualifiedName` | fully qualified compile-time name |
| `isTemplate` | whether the symbol is a template declaration |
| `isModule` | whether the symbol is a module |
| `isPackage` | whether the symbol is a package |
| `isNested` | whether the declaration has lexical nesting |
| `isDeprecated` | whether the declaration is deprecated |
| `isDisabled` | whether the declaration is disabled |
| `isSame` | whether two arguments denote the same type, symbol, alias, or compile-time entity |

## Members and relationships

| Trait | Result |
| --- | --- |
| `hasMember` | whether the named member exists |
| `getMember` | named member symbol or expression |
| `getOverloads` | overload sequence for a name |
| `allMembers` | sequence of all member names |
| `derivedMembers` | sequence of members introduced by the declaration |
| `parent` | lexical parent of a symbol |

Member names, symbols, and overload sets are compile-time entities. Using a
returned member follows the ordinary access and call rules.

`getOverloads` excludes template overloads by default. Passing `true` as its
optional final argument includes both template and non-template overloads.
This behavior is the same when the aggregate operand is a type or a value.

## Declaration and target metadata

| Trait | Result |
| --- | --- |
| `getAttributes` | user-defined attribute sequence |
| `getLinkage` | linkage name |
| `getLocation` | source filename, line, and column |
| `getCppNamespaces` | C++ namespace sequence |
| `getVisibility` | visibility name |
| `getProtection` | protection name |
| `getTargetInfo` | target information selected by a key |

For a Laser-D source declaration, `getAttributes` returns an empty sequence.
The remaining operations report compiler, declaration, linkage, or target
facts.

## Semantic probes

`__traits(compiles, arguments)` checks its arguments in a gagged compile-time
context. It returns true only when every argument is semantically valid.

```d
struct Record
{
    int value;
}

static assert(__traits(compiles, Record.init.value));
static assert(!__traits(compiles, Record.init.missing));
```

`__traits(isSame, left, right)` tests compile-time identity:

```d
static assert(__traits(isSame, Record, Record));
static assert(!__traits(isSame, Record, int));
```

For function literals, identity ignores parameter names but distinguishes
different expression structures.

Trait results may be used by templates, constraints, `static if`,
`static foreach`, `static assert`, and CTFE.
