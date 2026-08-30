/** Compile-time type descriptions for Laser-D programs. */
module laserd.typedesc;

import core.stdc.stddef : size_t;
import std.traits : Fields, PointerTarget,
    isDynamicArray, isFloatingPoint, isIntegral, isPointer,
    isStaticArray;

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

private enum bool is_character(T) =
    is(T == char) || is(T == wchar) || is(T == dchar);

private enum bool is_primitive(T) =
    is(T == void) || is(T == bool) || isIntegral!T || isFloatingPoint!T;

private template is_string(T)
{
    static if (is(T == Character[], Character))
        enum is_string =
            is(immutable Character == immutable char)
            || is(immutable Character == immutable wchar)
            || is(immutable Character == immutable dchar);
    else
        enum is_string = false;
}

private template FunctionReturn(T)
{
    static if (is(T Result == return))
        alias FunctionReturn = Result;
    else
        static assert(0, T.stringof ~ " has no return type");
}

private template FunctionParameters(T)
{
    static if (is(T Params == function))
        alias FunctionParameters = Params;
    else
        static assert(0, T.stringof ~ " has no parameters");
}

private template ArrayElement(T)
{
    static if (is(T == Element[], Element))
        alias ArrayElement = Element;
    else static if (is(T == Element[Length], Element, size_t Length))
        alias ArrayElement = Element;
    else
        static assert(0, T.stringof ~ " is not an array type");
}

private template primitive_type_of(T)
{
    static if (is(T == void))
        enum primitive_type_of = PrimitiveTypeKind.PRIMITIVE_TYPE_VOID;
    else static if (is(T == bool))
        enum primitive_type_of = PrimitiveTypeKind.PRIMITIVE_TYPE_BOOLEAN;
    else static if (is_character!T)
        enum primitive_type_of = PrimitiveTypeKind.PRIMITIVE_TYPE_CHARACTER;
    else static if (isFloatingPoint!T)
        enum primitive_type_of = PrimitiveTypeKind.PRIMITIVE_TYPE_FLOATING_POINT;
    else static if (__traits(isUnsigned, T))
        enum primitive_type_of = PrimitiveTypeKind.PRIMITIVE_TYPE_UNSIGNED_INTEGER;
    else
        enum primitive_type_of = PrimitiveTypeKind.PRIMITIVE_TYPE_SIGNED_INTEGER;
}

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
    // Function types are not value types and have no value size.
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

template TypeDescription(T)
{
    static if (is_string!T)
        alias TypeDescription = StringTypeDescription!T;
    else static if (isPointer!T)
        alias TypeDescription = PointerTypeDescription!T;
    else static if (is(T == function))
        alias TypeDescription = FunctionTypeDescription!T;
    else static if (is(T == struct))
        alias TypeDescription = StructTypeDescription!T;
    else static if (isStaticArray!T)
        alias TypeDescription = ArrayTypeDescription!T;
    else static if (isDynamicArray!T)
        alias TypeDescription = SliceTypeDescription!T;
    else static if (is_primitive!T)
        alias TypeDescription = PrimitiveTypeDescription!T;
    else
        static assert(0, "TypeDescription does not support " ~ T.stringof);
}

TypeDescription!T TypeDescription_of(T)()
{
    return TypeDescription!T.init;
}
