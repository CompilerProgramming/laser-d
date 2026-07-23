---
title: Associative arrays
status: rejected
source: ../spec/hash-map.dd
---

# Associative Arrays

> **Rejected in Laser-D:**
>
> D associative arrays are not part of Laser-D. Both an
> associative-array type `Value[Key]` and an associative-array literal are
> rejected during frontend semantic analysis.

This is a complete rejection, rather than a restriction to particular key
or value types. ImportC's internal compiler data structures do not expose D
associative arrays as an ImportC source feature.

## <a id="rationale"></a>Rationale

A built-in D associative array is a runtime-managed hash table. Insertion, lookup, removal, growth, iteration, hashing, equality, and destruction can
require hidden allocation, runtime hooks, and type metadata. Those requirements
conflict with Laser-D's lack of the D runtime and garbage collector and with its
preference for explicit storage and control flow.

Programs may implement a hash table as an ordinary struct over fixed, caller-provided, manually managed, or C-owned storage. Such a type uses explicit
methods and remains subject to the normal Laser-D rules for structs, pointers, slices, allocation, cleanup, and ranges.

## <a id="declarations"></a>Types and Declarations

> **Rejected in Laser-D:**
>
> The D type grammar form `Value[Key]` is rejected regardless
> of storage duration, qualifiers, aliases, nesting, or whether a value is ever
> inserted.

```d
int[int] values; // rejected
```

Fixed arrays use an integral compile-time dimension and remain available as
specified by the arrays chapter. The syntax is distinguished semantically: a
type in the brackets denotes a rejected associative array, while an integral
compile-time value denotes a fixed array.

## <a id="literals"></a>Literals

> **Rejected in Laser-D:**
>
> Key-value array literals are rejected, including literals
> whose value might otherwise be used only during compile-time execution.

```d
auto values = [1: 10
2: 20]; // rejected
```

Templates, CTFE, and `static if` cannot restore associative-array
literals or types. Every ordinary Laser-D restriction also applies during
compile-time execution.

## <a id="removing_keys"></a>Removing Keys

The built-in associative-array `remove` and `clear` operations are
unavailable because there can be no associative-array receiver.

## <a id="testing_membership"></a>Membership

The D associative-array membership expression `key in table` is
unavailable. The ordinary scalar and pointer uses of operators are unaffected.

## <a id="using_classes_as_key"></a>Class Keys

Classes are independently rejected in Laser-D. Associative arrays remain
rejected for all key types.

## <a id="using_struct_as_key"></a>Struct and Union Keys

Structs and unions remain supported value types, but they cannot be used to
form a built-in associative-array type. User-written containers may define an
explicit hashing and equality policy without changing this language rule.

## <a id="construction_assignment_entries"></a>Entry Construction and Assignment

Index assignment cannot implicitly construct or insert an associative-array
entry. User-written containers must expose insertion and replacement through
ordinary explicit methods.

## <a id="inserting_if_not_present"></a>Conditional Insertion

Built-in conditional insertion operations are unavailable. Any equivalent
behavior belongs to an explicitly implemented container.

## <a id="advanced_updating"></a>Entry Updating

Built-in associative-array update and entry-reference operations are
unavailable.

## <a id="runtime_initialization"></a>Runtime Initialization

Laser-D performs no associative-array runtime initialization. This also
means that immutable associative arrays are unavailable.

## <a id="construction_and_ref_semantic"></a>Storage and Value Semantics

D's associative-array reference semantics are not part of Laser-D. Storage
and ownership semantics for a user-written container are expressed by its
ordinary fields and methods.

## <a id="properties"></a>Properties and Operations

Associative-array properties such as `.length`, `.keys`, `.values`, `.rehash`, and `.byKey` are unavailable. This does not affect the
separately specified properties of fixed arrays and non-owning slices.

### <a id="iteration-ops"></a>Iteration Operations

Associative-array `foreach` is unavailable. A user-written container may
provide a validated Laser-D value-type range and use the ordinary range
iteration rules.

### <a id="lookup-ops"></a>Key Lookup Operations

Built-in indexing, lookup, membership, and default-value operations on
associative arrays are unavailable.

## <a id="examples"></a>Replacement Pattern

### <a id="aa_example"></a>Explicit Container

A replacement container should make capacity, backing storage, hashing, collision policy, insertion failure, and cleanup explicit. It may use fixed
arrays, non-owning slices, pointers, or C allocation according to the existing
Laser-D rules.

### <a id="aa_example_iteration"></a>Explicit Iteration

Such a container may expose ordinary methods or the validated struct-range
protocol. It cannot use `opApply` or delegate iteration.

## <a id="conformance"></a>Conformance Boundary

Laser-D conformance requires rejection tests for both associative-array
types and literals. No individual operation needs a separate runtime test once
the receiver type is rejected, although diagnostics for syntax that constructs
a literal remain independently covered.
