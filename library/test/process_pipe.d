import core.stdc.stdio : puts;
import core.stdc.stddef : size_t;
import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import core.stdc.string : strcmp;
import laserd.foundation.lifecycle : finalize, initialize;
import laserd.system :
    ProcessArgument,
    PROCESS_DETACHED,
    PROCESS_STDSTREAMS,
    PROCESS_STILL_ACTIVE,
    Process,
    Stream,
    Process_create,
    Process_destroy,
    Stream_create_pipe,
    Stream_destroy,
    Stream_read,
    Process_set_arguments,
    Process_set_executable,
    Process_set_flags,
    Process_spawn,
    Process_standard_output,
    Process_wait,
    Stream_write;
import laserd.thread : Thread_sleep;

enum childArgument = "--laser-d-process-child";
enum childMessage = "laser-d-process-child-output";

extern(C) int main(int argc, char** argv)
{
    if (argc > 1 && strcmp(argv[1], childArgument.ptr) == 0) {
        puts(childMessage.ptr);
        return EXIT_SUCCESS;
    }

    if (initialize() != 0) {
        puts("foundation_process_pipe: initialization failed");
        return EXIT_FAILURE;
    }

    Stream* pipe = Stream_create_pipe();
    if (pipe is null) {
        puts("foundation_process_pipe: pipe allocation failed");
        finalize();
        return EXIT_FAILURE;
    }

    enum pipeMessage = "pipe";
    auto pipeBytes = cast(const(ubyte)[]) pipeMessage;
    ubyte[4] pipeResult;
    size_t pipeWritten = Stream_write(pipe, pipeBytes);
    size_t pipeRead = Stream_read(pipe, pipeResult[]);
    bool passed =
        pipeWritten == pipeBytes.length &&
        pipeRead == pipeResult.length;
    if (!passed)
        puts("foundation_process_pipe: standalone pipe transfer failed");
    foreach (i; 0 .. pipeResult.length)
        if (pipeResult[i] != pipeBytes[i]) {
            puts("foundation_process_pipe: standalone pipe data mismatch");
            passed = false;
        }
    Stream_destroy(pipe);

    Process* process = Process_create();
    if (process is null) {
        puts("foundation_process_pipe: process allocation failed");
        finalize();
        return EXIT_FAILURE;
    }

    Process_set_executable(process, argv[0][0 .. stringLength(argv[0])]);
    ProcessArgument[1] arguments;
    arguments[0].data = childArgument.ptr;
    arguments[0].length = childArgument.length;
    Process_set_arguments(process, arguments[]);
    Process_set_flags(process, PROCESS_DETACHED | PROCESS_STDSTREAMS);

    if (Process_spawn(process) != PROCESS_STILL_ACTIVE) {
        puts("foundation_process_pipe: process spawn failed");
        Process_destroy(process);
        finalize();
        return EXIT_FAILURE;
    }

    ubyte[64] output;
    size_t outputLength = Stream_read(Process_standard_output(process), output[]);
    if (outputLength < childMessage.length) {
        puts("foundation_process_pipe: child output was too short");
        passed = false;
    } else
        foreach (i; 0 .. childMessage.length)
            if (output[i] != cast(ubyte) childMessage[i]) {
                puts("foundation_process_pipe: child output mismatch");
                passed = false;
            }

    int exitCode = PROCESS_STILL_ACTIVE;
    foreach (i; 0 .. 1000) {
        exitCode = Process_wait(process);
        if (exitCode != PROCESS_STILL_ACTIVE)
            break;
        Thread_sleep(1);
    }
    if (exitCode != EXIT_SUCCESS) {
        puts("foundation_process_pipe: child wait failed");
        passed = false;
    }

    Process_destroy(process);
    finalize();
    return passed ? EXIT_SUCCESS : EXIT_FAILURE;
}

size_t stringLength(const(char)* value)
{
    size_t length;
    while (value[length])
        ++length;
    return length;
}
