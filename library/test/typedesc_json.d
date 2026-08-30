// A deliberately small JSON round-trip demonstration for laserd.typedesc.
//
// Supported here: mutable structs, signed integers, booleans, const(char)[]
// strings without escapes, and fixed-size arrays of supported values. This is a
// demonstration of compile-time description traversal, not a general JSON API.
import core.stdc.stddef : size_t;
import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import core.stdc.string : memcmp, memcpy;
import laserd.memory : Arena, Arena_create_bump, Arena_destroy;
import laserd.rpmalloc : rpmalloc_finalize, rpmalloc_initialize;
import laserd.typedesc :
    PrimitiveTypeKind, TypeDescriptionKind, TypeDescription_of;
import std.traits : isIntegral;

private struct JsonWriter
{
    char[] output;
    size_t length;

    bool write_character(char value)
    {
        if (length == output.length)
            return false;
        output[length++] = value;
        return true;
    }

    bool write_text(const(char)[] value)
    {
        if (value.length > output.length - length)
            return false;
        if (value.length != 0)
            memcpy(output.ptr + length, value.ptr, value.length);
        length += value.length;
        return true;
    }

    bool write_string(const(char)[] value)
    {
        if (!write_character('"'))
            return false;
        foreach (character; value)
        {
            // Escaping is intentionally outside this demonstration.
            if (character == '"' || character == '\\' || character < 0x20)
                return false;
            if (!write_character(character))
                return false;
        }
        return write_character('"');
    }

    bool write_integer(T)(T value)
    {
        char[32] reversed;
        size_t count;
        bool negative;
        ulong magnitude;

        static if (__traits(isUnsigned, T))
            magnitude = cast(ulong) value;
        else
        {
            negative = value < 0;
            long signed_value = cast(long) value;
            magnitude = negative
                ? cast(ulong)(-(signed_value + 1)) + 1
                : cast(ulong) signed_value;
        }

        do
        {
            reversed[count++] = cast(char)('0' + magnitude % 10);
            magnitude /= 10;
        }
        while (magnitude != 0);

        if (negative && !write_character('-'))
            return false;
        while (count != 0)
            if (!write_character(reversed[--count]))
                return false;
        return true;
    }
}

private bool json_write(T)(ref JsonWriter writer, ref const T value)
{
    static if (is(T == const(char)[]))
        return writer.write_string(value);
    else
    {
        enum description = TypeDescription_of!T();
        static if (description.kind ==
            TypeDescriptionKind.TYPE_DESCRIPTION_PRIMITIVE)
        {
            static if (description.primitive_type ==
                PrimitiveTypeKind.PRIMITIVE_TYPE_BOOLEAN)
                return writer.write_text(value ? "true" : "false");
            else static if (isIntegral!T)
                return writer.write_integer(value);
            else
                static assert(0, "JSON demo supports only boolean and integer primitives");
        }
        else static if (description.kind ==
            TypeDescriptionKind.TYPE_DESCRIPTION_STRUCT)
        {
            if (!writer.write_character('{'))
                return false;
            static foreach (index; 0 .. description.field_count)
            {
                static if (index != 0)
                    if (!writer.write_character(','))
                        return false;
                if (!writer.write_string(description.field_name!index)
                    || !writer.write_character(':'))
                    return false;
                if (!json_write!(description.FieldType!index)(
                    writer, value.tupleof[index]))
                    return false;
            }
            return writer.write_character('}');
        }
        else static if (description.kind ==
            TypeDescriptionKind.TYPE_DESCRIPTION_ARRAY)
        {
            if (!writer.write_character('['))
                return false;
            foreach (index, ref element; value)
            {
                if (index != 0 && !writer.write_character(','))
                    return false;
                if (!json_write!(description.ElementType)(writer, element))
                    return false;
            }
            return writer.write_character(']');
        }
        else
            static assert(0,
                "JSON demo rejects pointer, function, and non-string slice values");
    }
}

private struct JsonReader
{
    const(char)[] input;
    size_t offset;

    void skip_whitespace()
    {
        while (offset < input.length
            && (input[offset] == ' ' || input[offset] == '\n'
                || input[offset] == '\r' || input[offset] == '\t'))
            ++offset;
    }

    bool consume(char expected)
    {
        skip_whitespace();
        if (offset == input.length || input[offset] != expected)
            return false;
        ++offset;
        return true;
    }

    bool read_string_view(out const(char)[] value)
    {
        skip_whitespace();
        if (offset == input.length || input[offset++] != '"')
            return false;
        size_t start = offset;
        while (offset < input.length && input[offset] != '"')
        {
            if (input[offset] == '\\' || cast(ubyte) input[offset] < 0x20)
                return false;
            ++offset;
        }
        if (offset == input.length)
            return false;
        value = input[start .. offset++];
        return true;
    }
}

private bool text_equals(const(char)[] left, const(char)[] right)
{
    return left.length == right.length
        && (left.length == 0 || memcmp(left.ptr, right.ptr, left.length) == 0);
}

private bool json_read_integer(T)(ref JsonReader reader, out T value)
{
    reader.skip_whitespace();
    bool negative;
    if (reader.offset < reader.input.length && reader.input[reader.offset] == '-')
    {
        negative = true;
        ++reader.offset;
    }
    if (reader.offset == reader.input.length
        || reader.input[reader.offset] < '0'
        || reader.input[reader.offset] > '9')
        return false;

    ulong magnitude;
    while (reader.offset < reader.input.length
        && reader.input[reader.offset] >= '0'
        && reader.input[reader.offset] <= '9')
    {
        uint digit = reader.input[reader.offset++] - '0';
        if (magnitude > (ulong.max - digit) / 10)
            return false;
        magnitude = magnitude * 10 + digit;
    }

    static if (__traits(isUnsigned, T))
    {
        if (negative || magnitude > T.max)
            return false;
        value = cast(T) magnitude;
    }
    else
    {
        ulong negative_limit = cast(ulong)(-(cast(long) T.min + 1)) + 1;
        if ((!negative && magnitude > cast(ulong) T.max)
            || (negative && magnitude > negative_limit))
            return false;
        value = negative
            ? cast(T)(-cast(long)(magnitude - (magnitude == negative_limit)))
                - cast(T)(magnitude == negative_limit)
            : cast(T) magnitude;
    }
    return true;
}

private bool json_read_string(
    ref JsonReader reader,
    Arena* arena,
    out const(char)[] value)
{
    const(char)[] source;
    if (!reader.read_string_view(source))
        return false;
    char[] storage = arena.allocArray!char(source.length);
    if (source.length != 0 && storage.ptr is null)
        return false;
    if (source.length != 0)
        memcpy(storage.ptr, source.ptr, source.length);
    value = storage;
    return true;
}

private bool json_read(T)(ref JsonReader reader, Arena* arena, out T value)
{
    static if (is(T == const(char)[]))
        return json_read_string(reader, arena, value);
    else
    {
        enum description = TypeDescription_of!T();
        static if (description.kind ==
            TypeDescriptionKind.TYPE_DESCRIPTION_PRIMITIVE)
        {
            static if (description.primitive_type ==
                PrimitiveTypeKind.PRIMITIVE_TYPE_BOOLEAN)
            {
                reader.skip_whitespace();
                if (reader.input.length - reader.offset >= 4
                    && text_equals(reader.input[reader.offset .. reader.offset + 4], "true"))
                {
                    reader.offset += 4;
                    value = true;
                    return true;
                }
                if (reader.input.length - reader.offset >= 5
                    && text_equals(reader.input[reader.offset .. reader.offset + 5], "false"))
                {
                    reader.offset += 5;
                    value = false;
                    return true;
                }
                return false;
            }
            else static if (isIntegral!T)
                return json_read_integer(reader, value);
            else
                static assert(0, "JSON demo supports only boolean and integer primitives");
        }
        else static if (description.kind ==
            TypeDescriptionKind.TYPE_DESCRIPTION_STRUCT)
        {
            value = T.init;
            if (!reader.consume('{'))
                return false;
            reader.skip_whitespace();
            if (reader.consume('}'))
                return true;
            while (true)
            {
                const(char)[] name;
                if (!reader.read_string_view(name) || !reader.consume(':'))
                    return false;
                bool matched;
                static foreach (index; 0 .. description.field_count)
                {
                    if (!matched && text_equals(name, description.field_name!index))
                    {
                        if (!json_read!(description.FieldType!index)(
                            reader, arena, value.tupleof[index]))
                            return false;
                        matched = true;
                    }
                }
                if (!matched)
                    return false;
                if (reader.consume('}'))
                    return true;
                if (!reader.consume(','))
                    return false;
            }
        }
        else static if (description.kind ==
            TypeDescriptionKind.TYPE_DESCRIPTION_ARRAY)
        {
            if (!reader.consume('['))
                return false;
            alias ElementType = description.ElementType;
            value = T.init;
            foreach (index; 0 .. description.element_count)
            {
                if (index != 0 && !reader.consume(','))
                    return false;
                if (!json_read!ElementType(reader, arena, value[index]))
                    return false;
            }
            if (!reader.consume(']'))
                return false;
            return true;
        }
        else
            static assert(0,
                "JSON demo rejects pointer, function, and non-string slice fields");
    }
}

private struct Reading
{
    int day;
    int value;
}

private struct Report
{
    const(char)[] station;
    int[3] calibration_values;
    Reading[2] readings;
}

extern(C) int main()
{
    if (rpmalloc_initialize(null) != 0)
        return EXIT_FAILURE;
    scope(exit) rpmalloc_finalize();

    int[3] calibration_storage = [-3, 5, 8];
    Reading[2] reading_storage = [Reading(1, 21), Reading(2, 34)];
    Report original;
    original.station = "north";
    original.calibration_values = calibration_storage;
    original.readings = reading_storage;

    char[512] output_storage;
    JsonWriter writer = JsonWriter(output_storage[], 0);
    if (!json_write!Report(writer, original))
        return EXIT_FAILURE;
    const(char)[] json = writer.output[0 .. writer.length];
    enum expected = `{"station":"north","calibration_values":[-3,5,8],"readings":[{"day":1,"value":21},{"day":2,"value":34}]}`;
    if (!text_equals(json, expected))
        return EXIT_FAILURE;

    Arena* arena = Arena_create_bump();
    if (arena is null)
        return EXIT_FAILURE;
    scope(exit) Arena_destroy(arena);

    JsonReader reader = JsonReader(json, 0);
    Report reconstructed;
    if (!json_read!Report(reader, arena, reconstructed))
        return EXIT_FAILURE;
    reader.skip_whitespace();
    if (reader.offset != reader.input.length)
        return EXIT_FAILURE;

    if (!text_equals(reconstructed.station, "north")
        || reconstructed.calibration_values.length != 3
        || reconstructed.calibration_values[2] != 8
        || reconstructed.readings.length != 2
        || reconstructed.readings[0].day != 1
        || reconstructed.readings[1].value != 34)
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}
