/**
 * Foundation unnamed pipes.
 *
 * A pipe is an opaque byte stream. Destroy it with
 * `laserd.foundation.stream.destroyStream`.
 */
module laserd.foundation.pipe;

import laserd.foundation.stream : stream_t;

extern(C):

stream_t* pipe_allocate();
void pipe_close_read(stream_t* pipe);
void pipe_close_write(stream_t* pipe);

stream_t* createPipe()
{
    return pipe_allocate();
}

void closeRead(stream_t* pipe)
{
    pipe_close_read(pipe);
}

void closeWrite(stream_t* pipe)
{
    pipe_close_write(pipe);
}
