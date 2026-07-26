import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import laserd.foundation.lifecycle : finalize, initialize;
import laserd.foundation.thread :
    THREAD_PRIORITY_NORMAL,
    create,
    destroy,
    join,
    start,
    thread_t;
import laserd.nsync :
    nsync_cv,
    nsync_cv_broadcast,
    nsync_cv_wait,
    nsync_mu,
    nsync_mu_lock,
    nsync_mu_rtrylock,
    nsync_mu_runlock,
    nsync_mu_trylock,
    nsync_mu_unlock;

struct NsyncTestData
{
    nsync_mu mutex;
    nsync_cv condition;
    int ready;
    int proceed;
    int value;
}

extern(C) void* nsyncWorker(void* argument)
{
    auto data = cast(NsyncTestData*) argument;

    nsync_mu_lock(&data.mutex);
    data.ready = 1;
    nsync_cv_broadcast(&data.condition);
    while (!data.proceed)
        nsync_cv_wait(&data.condition, &data.mutex);
    data.value = 42;
    nsync_mu_unlock(&data.mutex);

    return argument;
}

extern(C) int main()
{
    if (initialize() != 0)
        return EXIT_FAILURE;

    NsyncTestData data;
    enum workerName = "nsync-test";
    thread_t* worker = create(
        &nsyncWorker,
        &data,
        workerName,
        THREAD_PRIORITY_NORMAL,
        0);
    if (worker is null)
        return EXIT_FAILURE;
    if (!start(worker)) {
        destroy(worker);
        finalize();
        return EXIT_FAILURE;
    }

    nsync_mu_lock(&data.mutex);
    while (!data.ready)
        nsync_cv_wait(&data.condition, &data.mutex);
    data.proceed = 1;
    nsync_cv_broadcast(&data.condition);
    nsync_mu_unlock(&data.mutex);

    void* result = join(worker);
    bool passed = result == &data && data.value == 42;
    destroy(worker);

    if (nsync_mu_trylock(&data.mutex) == 0)
        passed = false;
    else
        nsync_mu_unlock(&data.mutex);

    if (nsync_mu_rtrylock(&data.mutex) == 0)
        passed = false;
    else
        nsync_mu_runlock(&data.mutex);

    finalize();
    return passed ? EXIT_SUCCESS : EXIT_FAILURE;
}
