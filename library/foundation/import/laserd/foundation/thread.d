/**
 * Basic Foundation thread creation and joining for Laser-D.
 *
 * Foundation must be initialized before creating a thread. Threads created by
 * this module automatically enter and leave Foundation and rpmalloc thread
 * state around the callback.
 */
module laserd.foundation.thread;

import core.stdc.stddef : size_t;
import core.stdc.stdint : uint64_t;

struct thread_t
{
}

alias ThreadFunction = extern(C) void* function(void*);
alias ThreadPriority = int;

enum ThreadPriority THREAD_PRIORITY_LOW = 0;
enum ThreadPriority THREAD_PRIORITY_BELOW_NORMAL = 1;
enum ThreadPriority THREAD_PRIORITY_NORMAL = 2;
enum ThreadPriority THREAD_PRIORITY_ABOVE_NORMAL = 3;
enum ThreadPriority THREAD_PRIORITY_HIGHEST = 4;
enum ThreadPriority THREAD_PRIORITY_TIME_CRITICAL = 5;

extern(C):

thread_t* thread_allocate(
    ThreadFunction function_,
    void* data,
    const(char)* name,
    size_t nameLength,
    ThreadPriority priority,
    uint stackSize);
void thread_deallocate(thread_t* thread);
bool thread_start(thread_t* thread);
void* thread_join(thread_t* thread);
bool thread_is_started(const(thread_t)* thread);
bool thread_is_running(const(thread_t)* thread);
bool thread_is_finished(const(thread_t)* thread);
bool thread_is_main();
uint64_t thread_id();
void thread_sleep(uint milliseconds);
void thread_yield();

thread_t* create(
    ThreadFunction function_,
    void* data,
    const(char)[] name,
    ThreadPriority priority,
    uint stackSize)
{
    return thread_allocate(
        function_, data, name.ptr, name.length, priority, stackSize);
}

void destroy(thread_t* thread)
{
    thread_deallocate(thread);
}

bool start(thread_t* thread)
{
    return thread_start(thread);
}

void* join(thread_t* thread)
{
    return thread_join(thread);
}

bool isStarted(const(thread_t)* thread)
{
    return thread_is_started(thread);
}

bool isRunning(const(thread_t)* thread)
{
    return thread_is_running(thread);
}

bool isFinished(const(thread_t)* thread)
{
    return thread_is_finished(thread);
}

bool isMain()
{
    return thread_is_main();
}

uint64_t currentId()
{
    return thread_id();
}

void sleep(uint milliseconds)
{
    thread_sleep(milliseconds);
}

void yield()
{
    thread_yield();
}
