import core.stdc.stdio : puts;
import core.stdc.stddef : size_t;
import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import core.stdc.string : strcmp;
import laserd.foundation.lifecycle : finalize, initialize;
import laserd.system :
    Argument,
    DETACHED,
    Process,
    REDIRECT_STREAMS,
    STILL_ACTIVE,
    Stream,
    createProcess,
    createPipe,
    destroyProcess,
    destroyStream,
    read,
    setArguments,
    setExecutable,
    setFlags,
    spawn,
    standardOutput,
    wait,
    write;
import laserd.thread : sleep;

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

    Stream* pipe = createPipe();
    if (pipe is null) {
        puts("foundation_process_pipe: pipe allocation failed");
        finalize();
        return EXIT_FAILURE;
    }

    enum pipeMessage = "pipe";
    auto pipeBytes = cast(const(ubyte)[]) pipeMessage;
    ubyte[4] pipeResult;
    size_t pipeWritten = write(pipe, pipeBytes);
    size_t pipeRead = read(pipe, pipeResult[]);
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
    destroyStream(pipe);

    Process* process = createProcess();
    if (process is null) {
        puts("foundation_process_pipe: process allocation failed");
        finalize();
        return EXIT_FAILURE;
    }

    setExecutable(process, argv[0][0 .. stringLength(argv[0])]);
    Argument[1] arguments;
    arguments[0].data = childArgument.ptr;
    arguments[0].length = childArgument.length;
    setArguments(process, arguments[]);
    setFlags(process, DETACHED | REDIRECT_STREAMS);

    if (spawn(process) != STILL_ACTIVE) {
        puts("foundation_process_pipe: process spawn failed");
        destroyProcess(process);
        finalize();
        return EXIT_FAILURE;
    }

    ubyte[64] output;
    size_t outputLength = read(standardOutput(process), output[]);
    if (outputLength < childMessage.length) {
        puts("foundation_process_pipe: child output was too short");
        passed = false;
    } else
        foreach (i; 0 .. childMessage.length)
            if (output[i] != cast(ubyte) childMessage[i]) {
                puts("foundation_process_pipe: child output mismatch");
                passed = false;
            }

    int exitCode = STILL_ACTIVE;
    foreach (i; 0 .. 1000) {
        exitCode = wait(process);
        if (exitCode != STILL_ACTIVE)
            break;
        sleep(1);
    }
    if (exitCode != EXIT_SUCCESS) {
        puts("foundation_process_pipe: child wait failed");
        passed = false;
    }

    destroyProcess(process);
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
