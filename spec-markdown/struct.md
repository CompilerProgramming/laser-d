---
title: Structs and unions
status: restricted
source: ../spec/struct.dd
---

# Structs and Unions

## <a id="intro"></a>Overview

Laser-D supports D structs and unions as runtime-free value types. They
provide named inline storage, explicit methods, ordinary construction, and
layout suitable for systems programming without a class hierarchy, garbage
collector, or D runtime.

> **Laser-D normative:**
>
> The rules in this chapter apply to native D structs and
> unions. ImportC retains C struct and union declarations under the ImportC
> specification. Struct declarations under C++ linkage are rejected.

### <a id="structs"></a>Structs

```text
StructDeclaration:
    struct Identifier { DeclDefs }
    struct Identifier ;
```

A struct value contains each non-static instance field. Structs do not
inherit, implement interfaces, or contain a hidden virtual-function table.

```d
d
struct Point
{
    int x;
    int y;

    int sum()
    {
        return x + y;
    }
}

```

### <a id="storage"></a>Storage

Struct and union storage may be local, embedded in another supported value, placed in a fixed array, or obtained explicitly through pointer or C allocation
facilities. The general Laser-D restrictions on mutable static storage apply.

A pointer to a forward-declared opaque struct or union is supported. A value
of an opaque aggregate cannot be instantiated until its definition is
available.

### <a id="unions"></a>Unions

```text
UnionDeclaration:
    union Identifier { DeclDefs }
    union Identifier ;
```

A union overlays its instance fields at the same address. Its size and
alignment accommodate every field. The language does not track which field is
currently active.

## <a id="struct-members"></a>Members

Struct and union bodies may contain fields, supported methods, ordinary
constructors, nested type declarations, manifest constants, templates, and
other declarations permitted by their individual Laser-D rules.

> **Rejected in Laser-D:**
>
> A member cannot restore a rejected language feature. In
> particular, aggregate bodies cannot contain destructors, postblits, invariants, `alias this`, mutable static fields, user-defined attributes, rejected
> function annotations, or native class/interface declarations.

### <a id="unions_and_special_memb_funct"></a>Union Member Restrictions

At most one overlapping union field may have a default initializer. A union
may have an ordinary constructor that explicitly initializes the intended
field. Laser-D does not implicitly destroy a previously active field.

### <a id="recursive-types"></a>Recursive Aggregates

A struct or union cannot contain itself recursively by value because its
size would be infinite. Recursion through a pointer is supported.

```d
d
struct Node
{
    int value;
    Node* next;
}

```

## <a id="struct_layout"></a>Layout

Fields are laid out in declaration order subject to target alignment and
padding rules. `.sizeof`, `.alignof`, field `.offsetof`, and
`.tupleof` expose the resulting compile-time information.

Struct layout is not a promise of cross-target binary identity. Portable
code must not assume padding, alignment, or endianness beyond the target ABI.
Interoperability code must verify the layout required by each external ABI.

## <a id="bitfields"></a>Bit Fields

```text
BitFieldDeclaration:
    BasicType Identifier : Expression ;
    BasicType Identifier : Expression = Expression ;
    BasicType : 0 ;
```

Signed and unsigned integral bit fields are supported in structs and
unions. Their widths are compile-time values no larger than their storage type.
An anonymous zero-width field forces the next field to a new allocation unit;
a named zero-width field is rejected.

Bit fields support ordinary access, assignment, permitted default
initializers, and the corresponding compile-time traits. Bit-field packing and
ordering are implementation-defined. External layouts must be verified for
every supported target.

## <a id="POD"></a>Plain Value Aggregates

A struct composed of ordinary value-copyable fields and without special
copy, move, or destruction behavior has direct value semantics. The
`__traits(isPOD)` and related supported traits may inspect this property.

## <a id="opaque_struct_unions"></a>Opaque Structs and Unions

A declaration ending in `;` introduces an opaque aggregate. Only
pointers and declarations that do not require its size are valid before a
matching definition is available.

## <a id="initialization"></a>Initialization

### <a id="default_struct_init"></a>Default Struct Initialization

Default initialization initializes each field using its permitted field
initializer or the field type's default initialization. Struct `.init`
denotes that compile-time default value when all required field initialization
is available.

### <a id="static_struct_init"></a>Static Struct Initialization

Struct values in permitted immutable static storage require an initializer
that is valid for static initialization. The general rejection of mutable
global and static storage applies independently.

### <a id="default_union_init"></a>Default Union Initialization

A union's default initialization is determined by its permitted default
field initializer or ordinary D union initialization rules. More than one
overlapping default field initializer is rejected.

### <a id="static_union_init"></a>Static Union Initialization

A union in permitted immutable static storage must have a statically valid
initial value. No runtime registration or lifecycle function is generated.

### <a id="dynamic_struct_init"></a>Runtime Struct Initialization

Local struct values may be initialized with field values, a struct literal, or an ordinary constructor. This performs no implicit allocation.

### <a id="dynamic_union_init"></a>Runtime Union Initialization

Local union values may be initialized according to the selected field or an
ordinary union constructor. The program is responsible for maintaining any
active-field convention.

## <a id="StructLiteral"></a>Struct Literals

A struct literal names the struct type and supplies compatible field values
in declaration order. Omitted fields receive their supported default
initialization.

```d
d
struct Point
{
    int x;
    int y;
}

Point origin = Point(0, 0);

```

## <a id="union-literal"></a>Union Literals

Union initialization must select a representation permitted by the union's
fields and constructors. It does not attach a hidden runtime tag.

## <a id="anonymous"></a>Anonymous Structs and Unions

Anonymous unions are supported for directly overlaying fields in a
containing aggregate. Anonymous structs and unions obey the same layout, initialization, and rejected-member rules as named aggregates.

## <a id="struct_instance_properties"></a>Struct Properties

Supported compile-time struct properties include `.sizeof`, `.alignof`, `.tupleof`, `.stringof`, and other properties classified
by the properties chapter. Properties cannot introduce TypeInfo, allocation, or another rejected runtime facility.

### <a id="struct_field_properties"></a>Field Properties

Fields expose supported properties such as `.offsetof`. Bit fields also
expose the supported bit-field traits and numeric bounds.

## <a id="ConstStruct"></a>Immutable Structs

Transitively `immutable` struct and union values are supported. The
rejected `const`, `inout`, and `shared` qualifiers remain unavailable
for aggregate types, fields, receivers, and methods.

## <a id="UnionConstructor"></a>Union Constructors

An ordinary union constructor may explicitly initialize one representation.
It obeys every ordinary Laser-D function restriction.

## <a id="Struct-Constructor"></a>Struct Constructors

Ordinary struct constructors are supported as a convenience for initializing
small value types. A constructor is named `this`, returns no source-level
value, and initializes the existing destination storage.

> **Rejected in Laser-D:**
>
> A constructor cannot be declared with a source-level `ref`
> return annotation. Constructor contracts, attributes rejected by Laser-D, allocation through `new`, and lifecycle behavior through a destructor or
> postblit are also rejected.

### <a id="delegating-constructor"></a>Constructor Delegation

> **Rejected in Laser-D:**
>
> A struct constructor cannot delegate to another constructor
> with `this(...)`. Constructors initialize their fields directly.

### <a id="struct-instantiation"></a>Struct Instantiation

A struct is instantiated in existing storage by declaration, literal, assignment, parameter passing, return, or placement performed through explicit
pointer/C storage management. Every `new` expression is rejected.

### <a id="constructor-attributes"></a>Constructor Function Rules

Constructors inherit Laser-D's implicit function attributes and may not
spell rejected attributes or parameter/return annotations. Templated
constructors are supported when their bodies and inferred instances use only
supported features.

#### <a id="pure-constructors"></a>Purity

Laser-D does not expose D's explicit or inferred `pure` function
attribute. Constructors follow the same conservative function model as every
other function.

### <a id="disable_default_construction"></a>Disabled Default Construction

> **Rejected in Laser-D:**
>
> `@disable this()` and every other explicit use of
> `@disable` are rejected. Laser-D structs cannot opt out of ordinary default
> initialization through an attribute.

### <a id="field-init"></a>Constructor Field Initialization

A constructor may assign or initialize its fields explicitly. All fields
must have a valid state before they are read. Union constructors must respect
the program's selected active-field convention.

## <a id="StructCopyConstructor"></a>Copy Constructors

> **Rejected in Laser-D:**
>
> User-defined struct copy constructors are rejected. Laser-D
> supports ordinary field-wise value copying for aggregates whose fields are
> value-copyable and which require no postblit or destructor.

### <a id="disable-copy"></a>Disabled Copying

> **Rejected in Laser-D:**
>
> Attribute-driven disabled copying is rejected together with
> `@disable` and user-defined copy constructors.

### <a id="copy-constructor-attributes"></a>Copy Constructor Attributes

No copy-constructor-specific attribute surface is currently guaranteed.

### <a id="implicit-copy-constructors"></a>Implicit Copying

The frontend may generate ordinary field-wise copying required to implement
value semantics. It must not invoke a rejected source postblit.

## <a id="StructMoveConstructor"></a>Move Constructors

> **Rejected in Laser-D:**
>
> User-defined struct move constructors are rejected. Laser-D
> provides no general ownership transfer or moved-from-state model.

### <a id="disable-move"></a>Disabled Moving

> **Rejected in Laser-D:**
>
> Attribute-driven disabled moving is rejected together with
> `@disable` and user-defined move constructors.

### <a id="move-constructor-attributes"></a>Move Constructor Attributes

No move-constructor-specific attribute surface is currently guaranteed.

### <a id="implicit-move-constructors"></a>Implicit Moving

Frontend/backend transfer optimizations do not create a source-visible
ownership feature or permit the rejected `__rvalue` expression.

## <a id="StructPostblit"></a>Struct Postblits

> **Rejected in Laser-D:**
>
> A source declaration `this(this)` is rejected. Copying a
> Laser-D struct does not invoke a user-defined post-copy hook.

## <a id="member-functions"></a>Member Functions

Struct and union methods are supported ordinary functions with an explicit
call in source. They receive their aggregate context without a class object
model or virtual dispatch. Immutable receiver methods are supported; rejected
qualifiers and function annotations remain unavailable.

## <a id="StructDestructor"></a>Struct Destructors

> **Rejected in Laser-D:**
>
> A source struct or union destructor `~this()` is rejected.
> Laser-D does not schedule hidden user-defined work when an aggregate leaves
> scope, is overwritten, or is copied.

## <a id="union-field-destruction"></a>Union Field Destruction

Laser-D performs no implicit destruction of a union field. Programs needing
resource release use explicit functions or the supported `scope(exit)`
statement around an explicitly managed resource.

## <a id="Invariant"></a>Struct Invariants

> **Rejected in Laser-D:**
>
> Aggregate `invariant` declarations are rejected. Validation
> must be expressed as an ordinary explicitly called method or function.

## <a id="AssignOverload"></a>Assignment Overloading

Modern `opAssign` and related operator hooks are supported only as
specified by the operator-overloading chapter. They are ordinary explicit
method calls after frontend lowering and remain subject to all aggregate and
function restrictions. Legacy D1 hooks are rejected.

## <a id="AliasThis"></a>Alias This

> **Rejected in Laser-D:**
>
> Both `alias member this` and `alias this = member` are
> rejected. Member lookup and conversions never implicitly forward through an
> aggregate field.

## <a id="nested"></a>Nested Structs

A struct declared inside another aggregate or namespace is supported when
it has ordinary value semantics. A function-local struct containing only
context-free value storage is also supported.

> **Rejected in Laser-D:**
>
> A nested struct that requires a hidden pointer to an enclosing
> function or aggregate context is rejected. Outer values must instead be passed
> explicitly as fields or function parameters.

## <a id="cpp-structs"></a>C++ Structs

> **Rejected in Laser-D:**
>
> Struct declarations under `extern(C++)` linkage are rejected, including forward declarations, definitions, templates, and explicit C++
> class/struct mangling forms. C++ free-function linkage is specified separately
> and remains available.

## <a id="conformance"></a>Conformance Boundary

The guaranteed aggregate subset consists of ordinary value storage, layout, fields, default and explicit initialization, literals, methods, direct
constructors, named and anonymous unions, and integral bit fields. Destructors, postblits, invariants, `alias this`, and C++ structs are rejected. Advanced
copy and move constructors, constructor delegation, `@disable`, and
hidden-context nested structs are rejected.
