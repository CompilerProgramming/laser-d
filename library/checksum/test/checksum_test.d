import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import laserd.checksum : checksum, laserd_checksum;

extern(C) int main()
{
    enum message = "Laser-D";
    enum expected = 616;

    auto bytes = cast(const(ubyte)[]) message;
    if (laserd_checksum(bytes.ptr, bytes.length) != expected)
        return EXIT_FAILURE;
    if (checksum(bytes) != expected)
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}
