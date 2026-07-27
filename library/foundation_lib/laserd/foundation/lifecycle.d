/**
 * Process-wide Foundation lifecycle using rpmalloc.
 *
 * A successful initialization owns rpmalloc until `finalize` is called.
 * Applications must not initialize or finalize rpmalloc independently while
 * Foundation is active.
 */
module laserd.foundation.lifecycle;

extern(C) int laserd_foundation_initialize_rpmalloc();
extern(C) void laserd_foundation_finalize();
extern(C) int laserd_foundation_is_initialized();

int initialize()
{
    return laserd_foundation_initialize_rpmalloc();
}

void finalize()
{
    laserd_foundation_finalize();
}

bool isInitialized()
{
    return laserd_foundation_is_initialized() != 0;
}
