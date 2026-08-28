/**
 * Portable child processes, anonymous pipes, and their byte streams.
 *
 * Pipe reads and writes are blocking. Pipe streams are sequential and cannot
 * be sought. Streams returned for a process's standard input, output, and
 * error are borrowed from the process and must not be destroyed separately.
 */
module laserd.system;

import core.stdc.stddef : size_t;

private:

struct stream_t
{
}

struct process_t
{
}

struct ProcessArgument
{
    const(char)* data;
    size_t length;
}

enum uint PROCESS_ATTACHED = 0;
enum uint PROCESS_DETACHED = 1U << 0;
enum uint PROCESS_CONSOLE = 1U << 1;
enum uint PROCESS_STDSTREAMS = 1U << 2;

enum int PROCESS_INVALID_ARGS = 0x7FFF_FFF0;
enum int PROCESS_TERMINATED_SIGNAL = 0x7FFF_FFF1;
enum int PROCESS_WAIT_INTERRUPTED = 0x7FFF_FFF2;
enum int PROCESS_WAIT_FAILED = 0x7FFF_FFF3;
enum int PROCESS_SYSTEM_CALL_FAILED = 0x7FFF_FFF4;
enum int PROCESS_STILL_ACTIVE = 0x7FFF_FFFF;

extern(C):

/**
 * Allocate a new process object. Deallocate it with `process_deallocate`.
 * Returns: the new process object
 */
process_t* process_allocate();

/** Deallocate a process object previously allocated by `process_allocate`. */
void process_deallocate(process_t* process);

/**
 * Set the process working directory. All process settings must be supplied
 * before spawning.
 */
void process_set_working_directory(
    process_t* process,
    const(char)* path,
    size_t length);

/** Set the executable path. */
void process_set_executable_path(
    process_t* process,
    const(char)* path,
    size_t length);

/**
 * Set command-line arguments. Do not include the executable path as the first
 * argument; it is added automatically.
 */
void process_set_arguments(
    process_t* process,
    const(ProcessArgument)* arguments,
    size_t count);

/** Set execution flags from the `PROCESS_*` definitions. */
void process_set_flags(process_t* process, uint flags);

/**
 * Spawn the process. Call `process_wait` when processing is done to reap the
 * child and avoid zombie processes.
 *
 * Returns: the exit code for an attached process, `PROCESS_STILL_ACTIVE` for a
 * detached process, or `PROCESS_INVALID_ARGS` for invalid arguments
 */
int process_spawn(process_t* process);

/**
 * Get the read-only stdout pipe. It is available only when
 * `PROCESS_STDSTREAMS` was set before spawning and is borrowed from the
 * process.
 */
stream_t* process_stdout(process_t* process);

/**
 * Get the read-only stderr pipe. It is available only when
 * `PROCESS_STDSTREAMS` was set before spawning and is borrowed from the
 * process.
 */
stream_t* process_stderr(process_t* process);

/**
 * Get the write-only stdin pipe. It is available only when
 * `PROCESS_STDSTREAMS` was set before spawning and is borrowed from the
 * process.
 */
stream_t* process_stdin(process_t* process);

/**
 * Wait for process termination.
 * Returns: the process exit code
 */
int process_wait(process_t* process);

/** Returns true if the child process was killed, otherwise false. */
bool process_kill(process_t* process);

/**
 * Allocate an unnamed, blocking, sequential pipe stream. Deallocate it with
 * `stream_deallocate`.
 */
stream_t* pipe_allocate();

/** Close the read end of a pipe. */
void pipe_close_read(stream_t* pipe);

/** Close the write end of a pipe. */
void pipe_close_write(stream_t* pipe);

/**
 * Deallocate a stream returned by a stream-specific allocation function.
 * Do not deallocate borrowed process standard streams.
 */
void stream_deallocate(stream_t* stream);

/** Returns true if the stream is at its end. */
bool stream_eos(stream_t* stream);

/**
 * Read raw data without byte-order conversion.
 * Returns: the number of bytes read
 */
size_t stream_read(stream_t* stream, void* destination, size_t size);

/**
 * Write raw data.
 * Returns: the number of bytes written
 */
size_t stream_write(stream_t* stream, const(void)* source, size_t size);

/**
 * Check the number of bytes that can be read without blocking.
 * Returns: the number of bytes available
 */
size_t stream_available_read(stream_t* stream);

/** Flush the stream. */
void stream_flush(stream_t* stream);

public:
extern(D):

alias Stream = stream_t;
alias Process = process_t;
alias Argument = ProcessArgument;

alias ATTACHED = PROCESS_ATTACHED;
alias DETACHED = PROCESS_DETACHED;
alias CONSOLE = PROCESS_CONSOLE;
alias REDIRECT_STREAMS = PROCESS_STDSTREAMS;

alias INVALID_ARGUMENTS = PROCESS_INVALID_ARGS;
alias TERMINATED_BY_SIGNAL = PROCESS_TERMINATED_SIGNAL;
alias WAIT_INTERRUPTED = PROCESS_WAIT_INTERRUPTED;
alias WAIT_FAILED = PROCESS_WAIT_FAILED;
alias SYSTEM_CALL_FAILED = PROCESS_SYSTEM_CALL_FAILED;
alias STILL_ACTIVE = PROCESS_STILL_ACTIVE;

alias Process_standard_output = process_stdout;
alias Process_standard_error = process_stderr;
alias Process_standard_input = process_stdin;

Process* Process_create()
{
    return process_allocate();
}

void Process_destroy(Process* process)
{
    process_deallocate(process);
}

void Process_set_working_directory(Process* process, const(char)[] path)
{
    process_set_working_directory(process, path.ptr, path.length);
}

void Process_set_executable(Process* process, const(char)[] path)
{
    process_set_executable_path(process, path.ptr, path.length);
}

void Process_set_arguments(
    Process* process,
    const(Argument)[] arguments)
{
    process_set_arguments(process, arguments.ptr, arguments.length);
}

void Process_set_flags(Process* process, uint flags)
{
    process_set_flags(process, flags);
}

int Process_spawn(Process* process)
{
    return process_spawn(process);
}

int Process_wait(Process* process)
{
    return process_wait(process);
}

bool Process_kill(Process* process)
{
    return process_kill(process);
}

Stream* Process_create_pipe()
{
    return pipe_allocate();
}

void Stream_close_read(Stream* pipe)
{
    pipe_close_read(pipe);
}

void Stream_close_write(Stream* pipe)
{
    pipe_close_write(pipe);
}

size_t Stream_read(Stream* stream, ubyte[] destination)
{
    return stream_read(stream, destination.ptr, destination.length);
}

size_t Stream_write(Stream* stream, const(ubyte)[] source)
{
    return stream_write(stream, source.ptr, source.length);
}

void Stream_destroy(Stream* stream)
{
    stream_deallocate(stream);
}
