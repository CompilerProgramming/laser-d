import core.stdc.stdlib : EXIT_SUCCESS;
import laserd.typedesc;

private struct Point
{
    int x;
    double y;
}

private struct Node
{
    Node* next;
}

private int transform(Point* point, float scale)
{
    return point.x + cast(int) scale;
}

enum integer_description = TypeDescription_of!int();
static assert(integer_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_PRIMITIVE);
static assert(integer_description.primitive_type ==
    PrimitiveTypeKind.PRIMITIVE_TYPE_SIGNED_INTEGER);
static assert(integer_description.size_in_bytes == int.sizeof);
static assert(integer_description.name == "int");
static assert(TypeDescription_of!bool().primitive_type ==
    PrimitiveTypeKind.PRIMITIVE_TYPE_BOOLEAN);
static assert(TypeDescription_of!uint().primitive_type ==
    PrimitiveTypeKind.PRIMITIVE_TYPE_UNSIGNED_INTEGER);
static assert(TypeDescription_of!char().primitive_type ==
    PrimitiveTypeKind.PRIMITIVE_TYPE_CHARACTER);
static assert(TypeDescription_of!double().primitive_type ==
    PrimitiveTypeKind.PRIMITIVE_TYPE_FLOATING_POINT);
static assert(TypeDescription_of!void().primitive_type ==
    PrimitiveTypeKind.PRIMITIVE_TYPE_VOID);
static assert(TypeDescription_of!void().size_in_bytes == void.sizeof);

enum pointer_description = TypeDescription_of!(Point*)();
static assert(pointer_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_POINTER);
static assert(is(pointer_description.TargetType == Point));
static assert(pointer_description.target_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_STRUCT);

enum function_pointer_description = TypeDescription_of!(typeof(&transform))();
static assert(function_pointer_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_POINTER);
static assert(function_pointer_description.target_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_FUNCTION);

enum function_description = TypeDescription_of!(typeof(transform))();
static assert(function_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_FUNCTION);
static assert(is(function_description.ReturnType == int));
static assert(function_description.return_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_PRIMITIVE);
static assert(function_description.parameter_count == 2);
static assert(is(function_description.ParameterType!0 == Point*));
static assert(function_description.parameter_description!0.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_POINTER);
static assert(is(function_description.ParameterType!1 == float));

enum point_description = TypeDescription_of!Point();
static assert(point_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_STRUCT);
static assert(point_description.size_in_bytes == Point.sizeof);
static assert(point_description.alignment_in_bytes == Point.alignof);
static assert(point_description.field_count == 2);
static assert(point_description.field_name!0 == "x");
static assert(point_description.field_name!1 == "y");
static assert(point_description.field_offset_in_bytes!0 == Point.x.offsetof);
static assert(is(point_description.FieldType!0 == int));
static assert(point_description.field_description!1.primitive_type ==
    PrimitiveTypeKind.PRIMITIVE_TYPE_FLOATING_POINT);

enum node_description = TypeDescription_of!Node();
static assert(node_description.field_count == 1);
static assert(is(node_description.FieldType!0 == Node*));

enum array_description = TypeDescription_of!(Point[2])();
static assert(array_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_ARRAY);
static assert(is(array_description.ElementType == Point));
static assert(array_description.element_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_STRUCT);
static assert(array_description.element_count == 2);

enum static_array_description = TypeDescription_of!(int[3])();
static assert(static_array_description.element_count == 3);
static assert(is(static_array_description.ElementType == int));

enum string_description = TypeDescription_of!(const(char)[])();
static assert(string_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_STRING);
static assert(is(string_description.CharacterType == const char));

enum slice_description = TypeDescription_of!(int[])();
static assert(slice_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_SLICE);
static assert(is(slice_description.ElementType == int));
static assert(slice_description.size_in_bytes == (int[]).sizeof);
static assert(slice_description.element_description.kind ==
    TypeDescriptionKind.TYPE_DESCRIPTION_PRIMITIVE);

extern(C) int main()
{
    return EXIT_SUCCESS;
}
