# Processes and byte streams: laserd.system

Source: `library/laserd/system.d`. Initialize [Foundation](foundation.md)
before using its allocating process/pipe operations. Link `laserd_foundation`,
`laserd_rpmalloc`, and platform dependencies from [building](building.md).

Foundation process and pipe support is exposed through the narrow
`laserd.system` module. Processes and streams are opaque.
Executable paths, working directories, and arguments are copied into the
process object. Redirected standard streams are borrowed from their process
and are released when the process is destroyed.
Before destroying a detached process, callers must successfully wait for it,
or kill it and then wait for termination.

The public stream surface contains raw byte reads and writes and destruction.
Unnamed pipes support allocation and closing either endpoint. Native handles/file descriptors, stream vtables,
typed stream serialization, platform-specific process launch modes, and
process-global exit operations are intentionally not exposed.

## Types and constants

```d
struct stream_t
{
}

struct process_t
{
}

alias Stream = stream_t;
alias Process = process_t;

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
```

`Stream` and `Process` are opaque; use pointers returned by factories.
`ProcessArgument` describes an argument as a pointer plus byte length.
Arguments exclude the executable path, which is added automatically.
`PROCESS_*` flags control attached/detached launch, console creation, and
redirected standard streams. Integer status constants distinguish launch/wait
errors and a still-active child from ordinary exit codes.

## Functions

These signatures use public type names; direct aliases retain C linkage and
slice-converting wrappers use D linkage.

```d
Stream* Process_standard_output(Process* process);
Stream* Process_standard_error(Process* process);
Stream* Process_standard_input(Process* process);
Process* Process_create();
void Process_destroy(Process* process);
void Process_set_flags(Process* process, uint flags);
int Process_spawn(Process* process);
int Process_wait(Process* process);
bool Process_kill(Process* process);
Stream* Stream_create_pipe();
void Stream_close_read(Stream* pipe);
void Stream_close_write(Stream* pipe);
void Stream_destroy(Stream* stream);
void Process_set_working_directory(Process* process, const(char)[] path);
void Process_set_executable(Process* process, const(char)[] path);
void Process_set_arguments(
    Process* process,
    const(ProcessArgument)[] arguments);
size_t Stream_read(Stream* stream, ubyte[] destination);
size_t Stream_write(Stream* stream, const(ubyte)[] source);
```

| Functions | Behavior |
| --- | --- |
| `Process_create`, `Process_destroy` | Allocate/release the process object and its owned streams. |
| `Process_set_working_directory`, `Process_set_executable`, `Process_set_arguments`, `Process_set_flags` | Configure before spawning; string/argument data is copied into the process object. |
| `Process_spawn` | Return attached exit code, `PROCESS_STILL_ACTIVE` for a detached launch, or a failure status. |
| `Process_wait`, `Process_kill` | Wait/reap and return exit status; kill returns Boolean success and must still be followed by a successful wait. |
| `Process_standard_output`, `Process_standard_error`, `Process_standard_input` | Borrow streams created with `PROCESS_STDSTREAMS`; output/error are readable and input is writable. |
| `Stream_create_pipe`, `Stream_close_read`, `Stream_close_write` | Allocate an unnamed pipe and close either endpoint. |
| `Stream_read`, `Stream_write` | Blocking raw byte I/O; return actual transferred byte count, which callers must check. |
| `Stream_destroy` | Destroy an owned pipe stream, never a borrowed process standard stream. |

The native declarations for flush, end-of-stream, and read-availability queries
are currently private: there are no public `Stream_flush`, `Stream_eos`, or
`Stream_available_read` functions. Drain redirected output and close input as
needed before waiting, so a child does not remain blocked on pipe I/O.

Integration coverage: `library/test/process_pipe.d` (CTest `foundation_process_pipe`).
