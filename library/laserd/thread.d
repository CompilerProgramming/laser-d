/**
 * Portable threads, mutexes, and condition variables for Laser-D.
 *
 * Foundation must be initialized before creating a thread. Threads created by
 * this module automatically enter and leave Foundation and rpmalloc thread
 * state around the callback.
 *
 * Synchronization and memory visibility:
 *
 * A successful exclusive or shared mutex acquisition has acquire semantics,
 * and releasing either mode has release semantics. A release of a mutex
 * happens before a later successful acquisition of the same mutex. Ordinary
 * non-atomic data written while holding the mutex is therefore visible to a
 * thread that subsequently acquires that mutex. Shared acquisitions may
 * overlap only when every holder reads the protected data; mutation requires
 * an exclusive acquisition.
 *
 * `wait` releases the supplied mutex with release semantics and reacquires it
 * with acquire semantics before returning. `signal` and `broadcast` only wake
 * waiters: they do not publish unprotected data by themselves. Change and test
 * the condition predicate while holding the same mutex, and always test it in
 * a loop.
 *
 * Starting a thread publishes the argument data initialized before `start` to
 * its callback. A completed `join` makes the callback's preceding writes
 * visible to the joining thread. The argument and any referenced storage must
 * remain alive until the thread has been joined.
 *
 * Laser-D does not provide `shared` types or language-level atomics. Programs
 * must protect every conflicting concurrent access with these mutex
 * operations or an explicitly reviewed foreign synchronization API.
 */
module laserd.thread;

import core.stdc.stddef : size_t;
import core.stdc.stdint : uint64_t;

struct thread_t
{
}

alias Thread = thread_t;
alias ThreadFunction = extern(C) void* function(void*);
alias ThreadPriority = int;

enum ThreadPriority THREAD_PRIORITY_LOW = 0;
enum ThreadPriority THREAD_PRIORITY_BELOW_NORMAL = 1;
enum ThreadPriority THREAD_PRIORITY_NORMAL = 2;
enum ThreadPriority THREAD_PRIORITY_ABOVE_NORMAL = 3;
enum ThreadPriority THREAD_PRIORITY_HIGHEST = 4;
enum ThreadPriority THREAD_PRIORITY_TIME_CRITICAL = 5;

private:

/**
 * A mutex is valid and unlocked when zero initialized. It may be held by one
 * thread in write (exclusive) mode or by many threads in read (shared) mode.
 *
 * A thread that acquires a mutex must release it. Acquiring in one thread and
 * releasing in another is illegal. A thread must not reacquire a mutex it
 * already holds, including a second read lock.
 *
 * Unlocking has release semantics. A later successful acquisition of the same
 * mutex has acquire semantics and observes writes made before the unlock.
 */
struct nsync_mu
{
    private uint word;
    private uint padding;
    private void* waiters;
}

/**
 * A zero-initialized Mesa-style condition variable. Waiters must test their
 * predicate in a loop because waits may wake spuriously and the predicate may
 * become false again before the awakened thread reacquires the mutex.
 */
struct nsync_cv
{
    private uint word;
    private uint padding;
    private void* waiters;
}

static assert(nsync_mu.sizeof == 16);
static assert(nsync_mu.word.offsetof == 0);
static assert(nsync_mu.waiters.offsetof == 8);
static assert(nsync_cv.sizeof == 16);
static assert(nsync_cv.word.offsetof == 0);
static assert(nsync_cv.waiters.offsetof == 8);

extern(C):

/**
 * Allocate a new thread.
 *
 * Params:
 *   function_ = thread execution function
 *   data = argument sent to the execution function
 *   name = thread name
 *   nameLength = length of the thread name
 *   priority = thread priority
 *   stackSize = thread stack size
 * Returns: the new thread
 */
thread_t* thread_allocate(
    ThreadFunction function_,
    void* data,
    const(char)* name,
    size_t nameLength,
    ThreadPriority priority,
    uint stackSize);

/** Deallocate a thread previously allocated by `thread_allocate`. */
void thread_deallocate(thread_t* thread);

/**
 * Start execution of a thread. This must be paired with `thread_join`.
 * Returns: true on success, otherwise false
 */
bool thread_start(thread_t* thread);

/**
 * Join a started thread and free its system resources.
 * Returns: the thread callback's exit value
 */
void* thread_join(thread_t* thread);

/** Returns true if the thread has started execution. */
bool thread_is_started(const(thread_t)* thread);

/** Returns true if the thread is running. */
bool thread_is_running(const(thread_t)* thread);

/** Returns true if the thread has completed and is safe to join. */
bool thread_is_finished(const(thread_t)* thread);

/** Returns true if the calling thread is the main thread. */
bool thread_is_main();

/** Returns the calling thread's system identifier. */
uint64_t thread_id();

/** Sleep the calling thread for the specified number of milliseconds. */
void thread_sleep(uint milliseconds);

/** Yield the calling thread's remaining time slice to other threads. */
void thread_yield();

/** Zero a mutex to initialize it as valid and unlocked. */
void nsync_mu_init(nsync_mu* mutex);

/**
 * Block until the mutex is free, then acquire it in write mode. The calling
 * thread must not already hold the mutex in any mode.
 */
void nsync_mu_lock(nsync_mu* mutex);

/**
 * Release a mutex held in write mode by the calling thread and wake waiters
 * when appropriate.
 */
void nsync_mu_unlock(nsync_mu* mutex);

/**
 * Attempt to acquire the mutex in write mode without blocking.
 * Returns: nonzero if acquired
 */
int nsync_mu_trylock(nsync_mu* mutex);

/**
 * Block until the mutex can be acquired in reader mode. The calling thread
 * must not already hold the mutex in any mode.
 */
void nsync_mu_rlock(nsync_mu* mutex);

/**
 * Release a mutex held in read mode by the calling thread and wake waiters
 * when appropriate.
 */
void nsync_mu_runlock(nsync_mu* mutex);

/**
 * Attempt to acquire the mutex in reader mode without blocking. This may fail
 * if a writer is waiting, to avoid starvation.
 * Returns: nonzero if acquired
 */
int nsync_mu_rtrylock(nsync_mu* mutex);

/** May abort unless the calling thread holds the mutex in write mode. */
void nsync_mu_assert_held(const(nsync_mu)* mutex);

/** May abort unless the calling thread holds the mutex in read or write mode. */
void nsync_mu_rassert_held(const(nsync_mu)* mutex);

/**
 * Query whether the mutex is held in read mode. The calling thread must hold
 * the mutex in some mode.
 */
int nsync_mu_is_reader(const(nsync_mu)* mutex);

/** Zero a condition variable to initialize it. */
void nsync_cv_init(nsync_cv* condition);

/**
 * Wake at least one thread currently blocked on the condition variable.
 * This does not replace locking the mutex that protects the predicate.
 */
void nsync_cv_signal(nsync_cv* condition);

/**
 * Wake all threads currently blocked on the condition variable.
 * This does not replace locking the mutex that protects the predicate.
 */
void nsync_cv_broadcast(nsync_cv* condition);

/**
 * Atomically release a held mutex and block on the condition variable. On a
 * signal, broadcast, or spurious wakeup, reacquire the mutex before returning.
 * The release has release semantics and the reacquisition has acquire
 * semantics. This function must be called in a loop that tests the protected
 * predicate while holding the mutex.
 */
void nsync_cv_wait(nsync_cv* condition, nsync_mu* mutex);

public:
extern(D):

alias Mutex = nsync_mu;
alias Condition = nsync_cv;

alias Mutex_init = nsync_mu_init;
alias Mutex_lock = nsync_mu_lock;
alias Mutex_unlock = nsync_mu_unlock;
alias Mutex_try_lock = nsync_mu_trylock;
alias Mutex_lock_shared = nsync_mu_rlock;
alias Mutex_unlock_shared = nsync_mu_runlock;
alias Mutex_try_lock_shared = nsync_mu_rtrylock;
alias Mutex_assert_locked = nsync_mu_assert_held;
alias Mutex_assert_locked_shared = nsync_mu_rassert_held;
alias Mutex_is_locked_shared = nsync_mu_is_reader;

alias Condition_init = nsync_cv_init;
alias Condition_signal = nsync_cv_signal;
alias Condition_broadcast = nsync_cv_broadcast;
alias Condition_wait = nsync_cv_wait;

Thread* Thread_create(
    ThreadFunction function_,
    void* data,
    const(char)[] name,
    ThreadPriority priority,
    uint stackSize)
{
    return thread_allocate(
        function_, data, name.ptr, name.length, priority, stackSize);
}

/** Deallocate a thread. */
alias Thread_destroy = thread_deallocate;
/** Start a thread. */
alias Thread_start = thread_start;
/** Join a thread and return its callback result. */
alias Thread_join = thread_join;
/** Return whether a thread has started. */
alias Thread_is_started = thread_is_started;
/** Return whether a thread is running. */
alias Thread_is_running = thread_is_running;
/** Return whether a thread has finished and can be joined. */
alias Thread_is_finished = thread_is_finished;
/** Return whether the calling thread is the main thread. */
alias Thread_is_main = thread_is_main;
/** Return the calling thread's system identifier. */
alias Thread_current_id = thread_id;
/** Sleep the calling thread for a number of milliseconds. */
alias Thread_sleep = thread_sleep;
/** Yield the calling thread's remaining time slice. */
alias Thread_yield = thread_yield;
