/**
 * Portable Foundation child-process management.
 *
 * Streams returned for standard input, output, and error are borrowed from
 * the process and must not be destroyed separately.
 *
 * Before destroying a detached process, the caller must successfully wait
 * for it or kill it and then wait for termination.
 */
module laserd.foundation.process;

import core.stdc.stddef : size_t;
import laserd.foundation.stream : stream_t;

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

process_t* process_allocate();
void process_deallocate(process_t* process);
void process_set_working_directory(
    process_t* process,
    const(char)* path,
    size_t length);
void process_set_executable_path(
    process_t* process,
    const(char)* path,
    size_t length);
void process_set_arguments(
    process_t* process,
    const(ProcessArgument)* arguments,
    size_t count);
void process_set_flags(process_t* process, uint flags);
int process_spawn(process_t* process);
stream_t* process_stdout(process_t* process);
stream_t* process_stderr(process_t* process);
stream_t* process_stdin(process_t* process);
int process_wait(process_t* process);
bool process_kill(process_t* process);

process_t* createProcess()
{
    return process_allocate();
}

void destroyProcess(process_t* process)
{
    process_deallocate(process);
}

void setWorkingDirectory(process_t* process, const(char)[] path)
{
    process_set_working_directory(process, path.ptr, path.length);
}

void setExecutable(process_t* process, const(char)[] path)
{
    process_set_executable_path(process, path.ptr, path.length);
}

void setArguments(
    process_t* process,
    const(ProcessArgument)[] arguments)
{
    process_set_arguments(process, arguments.ptr, arguments.length);
}

void setFlags(process_t* process, uint flags)
{
    process_set_flags(process, flags);
}

int spawn(process_t* process)
{
    return process_spawn(process);
}

int wait(process_t* process)
{
    return process_wait(process);
}

bool kill(process_t* process)
{
    return process_kill(process);
}
