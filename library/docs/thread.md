# Threads and synchronization: laserd.thread

Source: `library/laserd/thread.d`. Thread management uses `laserd_foundation`
and `laserd_rpmalloc`; synchronization uses `laserd_nsync` (vendored nsync
1.30.0). See [building](building.md) for platform linking. Foundation must be
initialized before creating workers. Supported native targets are x86-64
Windows, Linux, and macOS.

`laserd.thread` provides the initial thread-management surface:
opaque thread handles, callback-based creation, start, join, destruction,
status queries, current-thread identifiers, sleep, and yield. Foundation must
be initialized first. A Foundation-created worker automatically establishes
and releases Foundation and rpmalloc per-thread state around its callback.
Destruction joins a started worker if it has not already been joined.

Thread signalling, affinity, externally-created thread registration, and
caller-owned `Thread` storage is not yet exposed. Synchronization uses nsync
mutexes and condition variables through this same module.

## Types and constants

```d
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
```

`Thread` is an opaque handle type; use `Thread*`, not caller-owned storage.
`ThreadFunction` is a C callback receiving the supplied data pointer and
returning a result pointer. `Mutex` and `Condition` alias private native
structs, each 16 bytes on the supported ABI. Zero initialization makes both
valid; explicit init functions are also available. Do not copy active locks
or conditions or release their storage while in use.

## Functions

Signatures below use public type names. Most functions are public aliases to
private C entry points; only `Thread_create` needs a slice-converting wrapper.

```d
void Mutex_init(Mutex* mutex);
void Mutex_lock(Mutex* mutex);
void Mutex_unlock(Mutex* mutex);
int Mutex_try_lock(Mutex* mutex);
void Mutex_lock_shared(Mutex* mutex);
void Mutex_unlock_shared(Mutex* mutex);
int Mutex_try_lock_shared(Mutex* mutex);
void Mutex_assert_locked(const(Mutex)* mutex);
void Mutex_assert_locked_shared(const(Mutex)* mutex);
int Mutex_is_locked_shared(const(Mutex)* mutex);
void Condition_init(Condition* condition);
void Condition_signal(Condition* condition);
void Condition_broadcast(Condition* condition);
void Condition_wait(Condition* condition, Mutex* mutex);
void Thread_destroy(Thread* thread);
bool Thread_start(Thread* thread);
void* Thread_join(Thread* thread);
bool Thread_is_started(const(Thread)* thread);
bool Thread_is_running(const(Thread)* thread);
bool Thread_is_finished(const(Thread)* thread);
bool Thread_is_main();
uint64_t Thread_current_id();
void Thread_sleep(uint milliseconds);
void Thread_yield();
Thread* Thread_create(
    ThreadFunction function_,
    void* data,
    const(char)[] name,
    ThreadPriority priority,
    uint stackSize);
```

| Group | Behavior |
| --- | --- |
| `Thread_create`, `Thread_destroy` | Allocate a worker handle with callback, borrowed data, name, priority, and stack size; destroy after use. Destruction joins a started worker if needed. |
| `Thread_start`, `Thread_join` | Start returns Boolean success; join waits and returns the callback's pointer result. |
| `Thread_is_started`, `Thread_is_running`, `Thread_is_finished` | Worker status queries. |
| `Thread_is_main`, `Thread_current_id`, `Thread_sleep`, `Thread_yield` | Calling-thread query and scheduling operations; sleep duration is milliseconds. |
| `Mutex_lock`, `Mutex_unlock`, `Mutex_try_lock` | Exclusive acquisition/release; try returns nonzero on success. |
| `Mutex_lock_shared`, `Mutex_unlock_shared`, `Mutex_try_lock_shared` | Reader acquisition/release; try returns nonzero on success and may fail when a writer is waiting. |
| `Mutex_assert_locked`, `Mutex_assert_locked_shared` | Native checks for write ownership or read/write ownership. |
| `Mutex_is_locked_shared` | Reader-mode query; caller must already hold the mutex. |
| `Condition_wait`, `Condition_signal`, `Condition_broadcast` | Wait while temporarily releasing a held mutex; wake one or more waiters, or all waiters. |

A mutex is not recursive, even in reader mode. The acquiring thread must
release it; transferring unlock responsibility to another thread is invalid.

## Synchronization and memory visibility

Successful exclusive and reader acquisitions have acquire semantics; releasing
either mode has release semantics. A release happens before a later successful
acquisition of the same mutex, so ordinary writes made while holding it are
visible to the later holder. Concurrent reader holders must only read protected
data, and mutation requires the exclusive mode.

`Condition` variables use Mesa semantics. Waiting releases the mutex with
release semantics and reacquires it with acquire semantics before returning.
Signalling and broadcasting only wake waiters and do not publish unprotected
data independently. Change and test the predicate while holding the same mutex,
and retest it in a loop after every wakeup.

A successful thread start publishes the argument data initialized before
`start` to the callback. A completed `join` makes the callback's preceding
writes visible to the joining thread; the argument and referenced storage must
remain alive until then. Laser-D still has no `shared` qualifier or
language-level atomics. Every conflicting concurrent access must be protected
by these mutex operations or by another explicitly reviewed foreign
synchronization API.

Timed waits, cancellation notes, counters, once initialization, wait sets, and
conditional critical sections remain unexposed pending focused API and ABI
review.


Integration coverage: `library/test/thread_sync.d` (CTest `nsync_interop`).
