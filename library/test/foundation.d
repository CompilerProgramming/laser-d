// CMake links this focused ABI test with the vendored Foundation C library.
import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import laserd.foundation.base64 :
    base64_decode,
    base64_encode,
    decode,
    encode;
import laserd.foundation.hash : hash, hashBytes;
import laserd.foundation.lifecycle : finalize, initialize, isInitialized;
import laserd.thread :
    THREAD_PRIORITY_NORMAL,
    Thread,
    Thread_create,
    Thread_current_id,
    Thread_destroy,
    Thread_is_finished,
    Thread_is_main,
    Thread_is_started,
    Thread_join,
    Thread_start,
    Thread_yield;

struct ThreadTestData
{
    int value;
    int hasThreadId;
    int isWorkerMain;
}

extern(C) void* foundationThreadTest(void* argument)
{
    auto data = cast(ThreadTestData*) argument;
    data.value = 42;
    data.hasThreadId = Thread_current_id() != 0;
    data.isWorkerMain = Thread_is_main();
    return argument;
}

extern(C) int main()
{
    if (isInitialized())
        return EXIT_FAILURE;
    if (initialize() != 0 || !isInitialized())
        return EXIT_FAILURE;
    if (initialize() != 0 || !isInitialized())
        return EXIT_FAILURE;

    ThreadTestData threadData;
    enum threadName = "laser-d-test";
    Thread* thread = Thread_create(
        &foundationThreadTest,
        &threadData,
        threadName,
        THREAD_PRIORITY_NORMAL,
        0);
    if (thread is null)
        return EXIT_FAILURE;
    if (!Thread_start(thread)) {
        Thread_destroy(thread);
        return EXIT_FAILURE;
    }
    void* threadResult = Thread_join(thread);
    bool threadPassed =
        threadResult == &threadData &&
        Thread_is_started(thread) &&
        Thread_is_finished(thread) &&
        threadData.value == 42 &&
        threadData.hasThreadId &&
        !threadData.isWorkerMain;
    Thread_destroy(thread);
    if (!threadPassed)
        return EXIT_FAILURE;

    enum text = "engine";
    auto bytes = cast(const(ubyte)[]) text;

    if (hash(bytes.ptr, bytes.length) != 0x39c8cc157cfd24f8UL)
        return EXIT_FAILURE;
    if (hashBytes(bytes) != 0x39c8cc157cfd24f8UL)
        return EXIT_FAILURE;

    char[9] encoded;
    if (encode(bytes, encoded[]) != 9)
        return EXIT_FAILURE;
    if (encoded[0] != 'Z' || encoded[1] != 'W' ||
        encoded[2] != '5' || encoded[3] != 'n' ||
        encoded[4] != 'a' || encoded[5] != 'W' ||
        encoded[6] != '5' || encoded[7] != 'l' ||
        encoded[8] != 0)
        return EXIT_FAILURE;

    ubyte[6] decoded;
    if (decode(encoded[0 .. 8], decoded[]) != bytes.length)
        return EXIT_FAILURE;
    foreach (i; 0 .. bytes.length)
        if (decoded[i] != bytes[i])
            return EXIT_FAILURE;

    char[5] shortEncoding;
    if (base64_encode(
            bytes.ptr, bytes.length,
            shortEncoding.ptr, shortEncoding.length) != 5)
        return EXIT_FAILURE;
    if (shortEncoding[4] != 0)
        return EXIT_FAILURE;

    ubyte[3] shortDecode;
    if (base64_decode(
            encoded.ptr, 8, shortDecode.ptr, shortDecode.length) != 3)
        return EXIT_FAILURE;

    finalize();
    if (isInitialized())
        return EXIT_FAILURE;
    finalize();

    return EXIT_SUCCESS;
}
