/**
 * Minimal opaque byte-stream interface used by Foundation pipes and processes.
 */
module laserd.foundation.stream;

import core.stdc.stddef : size_t;

struct stream_t
{
}

extern(C):

void stream_deallocate(stream_t* stream);
bool stream_eos(stream_t* stream);
size_t stream_read(stream_t* stream, void* destination, size_t size);
size_t stream_write(stream_t* stream, const(void)* source, size_t size);
size_t stream_available_read(stream_t* stream);
void stream_flush(stream_t* stream);

size_t readStream(stream_t* stream, ubyte[] destination)
{
    return stream_read(stream, destination.ptr, destination.length);
}

size_t writeStream(stream_t* stream, const(ubyte)[] source)
{
    return stream_write(stream, source.ptr, source.length);
}

void destroyStream(stream_t* stream)
{
    stream_deallocate(stream);
}
