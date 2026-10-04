# Compile-time type descriptions: laserd.typedesc

Source: `library/laserd/typedesc.d`. No native archive or initialization is required.

`laserd.typedesc` provides opt-in compile-time descriptions as ordinary struct
values. Its initial surface covers primitive types, pointers, function types,
structs, static arrays, non-owning slices, and strings, including typed
traversal of pointer targets, function signatures, array and slice elements,
and named struct fields. Character slices receive the specific string
description. Description construction does not use Druntime `TypeInfo`,
`typeid`, allocation, or hidden compiler metadata.

The focused JSON demonstration serializes a described struct into
caller-provided storage and reconstructs string storage using a caller-provided
`Arena`. Its containing struct uses fixed-size arrays of primitives and structs.
The demonstration covers only the grammar needed to show recursive description
traversal and is not a public general-purpose JSON module.

## Entry points

```d
template TypeDescription(T); // Selects a descriptor struct type.
TypeDescription!T TypeDescription_of(T)(); // Returns that type's .init value.
```

Use `enum description = TypeDescription_of!T();` for a compile-time value.
Unsupported types produce a compile-time error. A function pointer is described
as a pointer whose target is a function type. Character slices select the string
description before the general slice description.

## Kinds

```d
enum TypeDescriptionKind : ubyte
{
    TYPE_DESCRIPTION_PRIMITIVE,
    TYPE_DESCRIPTION_POINTER,
    TYPE_DESCRIPTION_FUNCTION,
    TYPE_DESCRIPTION_STRUCT,
    TYPE_DESCRIPTION_ARRAY,
    TYPE_DESCRIPTION_SLICE,
    TYPE_DESCRIPTION_STRING,
}

enum PrimitiveTypeKind : ubyte
{
    PRIMITIVE_TYPE_VOID,
    PRIMITIVE_TYPE_BOOLEAN,
    PRIMITIVE_TYPE_SIGNED_INTEGER,
    PRIMITIVE_TYPE_UNSIGNED_INTEGER,
    PRIMITIVE_TYPE_CHARACTER,
    PRIMITIVE_TYPE_FLOATING_POINT,
}
```

## Descriptor structs and members

All descriptors expose `DescribedType`, `kind`, `size_in_bytes`, and `name`.
Function types have size zero because they are not value types. Array size is
the inline array's size; slice/string size is the slice representation's size,
not the number of elements it references. Indices below are compile-time
indices and must be in range. The following declarations list the additional
type aliases, fields, and compile-time traversal values for each struct:

```d
struct PrimitiveTypeDescription(T)
{
    alias DescribedType = T;

    TypeDescriptionKind kind =
        TypeDescriptionKind.TYPE_DESCRIPTION_PRIMITIVE;
    PrimitiveTypeKind primitive_type = primitive_type_of!T;
    size_t size_in_bytes = T.sizeof;
    immutable(char)[] name = T.stringof;
}

struct PointerTypeDescription(T)
{
    alias DescribedType = T;
    alias TargetType = PointerTarget!T;
    alias TargetDescription = TypeDescription!TargetType;

    TypeDescriptionKind kind =
        TypeDescriptionKind.TYPE_DESCRIPTION_POINTER;
    size_t size_in_bytes = T.sizeof;
    immutable(char)[] name = T.stringof;
    enum target_description = TypeDescription_of!TargetType();
}

struct FunctionTypeDescription(T)
{
    alias DescribedType = T;
    alias ReturnType = FunctionReturn!T;
    alias ReturnDescription = TypeDescription!ReturnType;
    alias ParameterTypes = FunctionParameters!T;
    alias ParameterType(size_t index) = ParameterTypes[index];
    alias ParameterDescription(size_t index) =
        TypeDescription!(ParameterType!index);

    TypeDescriptionKind kind =
        TypeDescriptionKind.TYPE_DESCRIPTION_FUNCTION;

    size_t size_in_bytes = 0;
    immutable(char)[] name = T.stringof;
    enum return_description = TypeDescription_of!ReturnType();
    enum parameter_count = ParameterTypes.length;
    enum parameter_description(size_t index) =
        TypeDescription_of!(ParameterType!index)();
}

struct StructTypeDescription(T)
{
    alias DescribedType = T;
    alias FieldTypes = Fields!T;
    alias FieldType(size_t index) = FieldTypes[index];
    alias FieldDescription(size_t index) = TypeDescription!(FieldType!index);

    TypeDescriptionKind kind = TypeDescriptionKind.TYPE_DESCRIPTION_STRUCT;
    size_t size_in_bytes = T.sizeof;
    size_t alignment_in_bytes = T.alignof;
    immutable(char)[] name = T.stringof;
    enum field_count = FieldTypes.length;
    enum field_description(size_t index) =
        TypeDescription_of!(FieldType!index)();
    enum field_name(size_t index) =
        __traits(identifier, T.tupleof[index]);
    enum field_offset_in_bytes(size_t index) = T.tupleof[index].offsetof;
}

struct ArrayTypeDescription(T)
{
    alias DescribedType = T;
    alias ElementType = ArrayElement!T;
    alias ElementDescription = TypeDescription!ElementType;

    TypeDescriptionKind kind = TypeDescriptionKind.TYPE_DESCRIPTION_ARRAY;
    size_t size_in_bytes = T.sizeof;
    immutable(char)[] name = T.stringof;
    enum element_count = T.length;
    enum element_description = TypeDescription_of!ElementType();
}

struct StringTypeDescription(T)
{
    alias DescribedType = T;
    alias CharacterType = ArrayElement!T;

    TypeDescriptionKind kind = TypeDescriptionKind.TYPE_DESCRIPTION_STRING;
    size_t size_in_bytes = T.sizeof;
    immutable(char)[] name = T.stringof;
}

struct SliceTypeDescription(T)
{
    alias DescribedType = T;
    alias ElementType = ArrayElement!T;
    alias ElementDescription = TypeDescription!ElementType;

    TypeDescriptionKind kind = TypeDescriptionKind.TYPE_DESCRIPTION_SLICE;
    size_t size_in_bytes = T.sizeof;
    immutable(char)[] name = T.stringof;
    enum element_description = TypeDescription_of!ElementType();
}
```

Integration coverage: `library/test/typedesc.d` (CTest
`compile_time_type_description`) and `library/test/typedesc_json.d` (CTest
`type_description_json_demo`). The latter requires an Arena for reconstructed
strings and rejects unsupported pointer, function, and non-string slice fields.
