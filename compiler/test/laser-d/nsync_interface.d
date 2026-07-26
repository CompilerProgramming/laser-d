import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import laserd.foundation.lifecycle : finalize, initialize;
import laserd.thread :
    Condition,
    Mutex,
    PRIORITY_NORMAL,
    Thread,
    broadcast,
    create,
    destroy,
    join,
    start,
    lock,
    tryLock,
    tryLockShared,
    unlock,
    unlockShared,
    wait;

struct NsyncTestData
{
    Mutex mutex;
    Condition condition;
    int ready;
    int proceed;
    int value;
}

extern(C) void* nsyncWorker(void* argument)
{
    auto data = cast(NsyncTestData*) argument;

    lock(&data.mutex);
    data.ready = 1;
    broadcast(&data.condition);
    while (!data.proceed)
        wait(&data.condition, &data.mutex);
    data.value = 42;
    unlock(&data.mutex);

    return argument;
}

extern(C) int main()
{
    if (initialize() != 0)
        return EXIT_FAILURE;

    NsyncTestData data;
    enum workerName = "nsync-test";
    Thread* worker = create(
        &nsyncWorker,
        &data,
        workerName,
        PRIORITY_NORMAL,
        0);
    if (worker is null)
        return EXIT_FAILURE;
    if (!start(worker)) {
        destroy(worker);
        finalize();
        return EXIT_FAILURE;
    }

    lock(&data.mutex);
    while (!data.ready)
        wait(&data.condition, &data.mutex);
    data.proceed = 1;
    broadcast(&data.condition);
    unlock(&data.mutex);

    void* result = join(worker);
    bool passed = result == &data && data.value == 42;
    destroy(worker);

    if (tryLock(&data.mutex) == 0)
        passed = false;
    else
        unlock(&data.mutex);

    if (tryLockShared(&data.mutex) == 0)
        passed = false;
    else
        unlockShared(&data.mutex);

    finalize();
    return passed ? EXIT_SUCCESS : EXIT_FAILURE;
}
