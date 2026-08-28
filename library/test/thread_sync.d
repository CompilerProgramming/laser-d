import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import laserd.foundation.lifecycle : finalize, initialize;
import laserd.thread :
    Condition,
    Mutex,
    PRIORITY_NORMAL,
    Thread,
    Condition_broadcast,
    Thread_create,
    Thread_destroy,
    Thread_join,
    Thread_start,
    Mutex_lock,
    Mutex_try_lock,
    Mutex_try_lock_shared,
    Mutex_unlock,
    Mutex_unlock_shared,
    Condition_wait;

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

    Mutex_lock(&data.mutex);
    data.ready = 1;
    Condition_broadcast(&data.condition);
    while (!data.proceed)
        Condition_wait(&data.condition, &data.mutex);
    data.value = 42;
    Mutex_unlock(&data.mutex);

    return argument;
}

extern(C) int main()
{
    if (initialize() != 0)
        return EXIT_FAILURE;

    NsyncTestData data;
    enum workerName = "nsync-test";
    Thread* worker = Thread_create(
        &nsyncWorker,
        &data,
        workerName,
        PRIORITY_NORMAL,
        0);
    if (worker is null)
        return EXIT_FAILURE;
    if (!Thread_start(worker)) {
        Thread_destroy(worker);
        finalize();
        return EXIT_FAILURE;
    }

    Mutex_lock(&data.mutex);
    while (!data.ready)
        Condition_wait(&data.condition, &data.mutex);
    data.proceed = 1;
    Condition_broadcast(&data.condition);
    Mutex_unlock(&data.mutex);

    void* result = Thread_join(worker);
    bool passed = result == &data && data.value == 42;
    Thread_destroy(worker);

    if (Mutex_try_lock(&data.mutex) == 0)
        passed = false;
    else
        Mutex_unlock(&data.mutex);

    if (Mutex_try_lock_shared(&data.mutex) == 0)
        passed = false;
    else
        Mutex_unlock_shared(&data.mutex);

    finalize();
    return passed ? EXIT_SUCCESS : EXIT_FAILURE;
}
