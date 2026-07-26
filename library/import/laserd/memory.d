/**
 * Laser-D bindings for rpmalloc 2.0.1.
 *
 * The native library is built without process-wide malloc replacement and
 * with the first-class heap API enabled.
 */
module laserd.memory;

import core.stdc.stddef : size_t;

private:

enum RPMALLOC_VERSION = "2.0.1";
enum RPMALLOC_VERSION_MAJOR = 2;
enum RPMALLOC_VERSION_MINOR = 0;
enum RPMALLOC_VERSION_PATCH = 1;
enum RPMALLOC_VERSION_NUMBER = 20_001;
enum RPMALLOC_CACHE_LINE_SIZE = 64;
enum RPMALLOC_MAX_ALIGNMENT = 256 * 1024;
enum RPMALLOC_NO_PRESERVE = 1;
enum RPMALLOC_GROW_OR_FAIL = 2;

struct rpmalloc_span_use_t
{
    size_t current;
    size_t map_calls;
}

struct rpmalloc_size_use_t
{
    size_t alloc_current;
    size_t alloc_peak;
    size_t alloc_total;
    size_t free_total;
}

struct rpmalloc_global_statistics_t
{
    size_t mapped;
    size_t mapped_peak;
    size_t committed;
    size_t decommitted;
    size_t active;
    size_t active_peak;
    size_t huge_alloc;
    size_t huge_alloc_peak;
    size_t heap_count;
}

struct rpmalloc_thread_statistics_t
{
    size_t sizecache;
    size_t spancache;
    rpmalloc_span_use_t[5] span_use;
    rpmalloc_size_use_t[128] size_use;
}

struct rpmalloc_interface_t
{
    /**
     * Map pages. The returned address must meet the requested alignment.
     * Supplying this callback requires also supplying `memory_unmap`; otherwise
     * the default implementation is used for both. Must be thread-safe.
     */
    extern(C) void* function(size_t, size_t, size_t*, size_t*) memory_map;

    /** Commit pages. Return nonzero if the range could not be committed. */
    extern(C) int function(void*, size_t) memory_commit;

    /** Decommit pages. Return nonzero if the range could not be decommitted. */
    extern(C) int function(void*, size_t) memory_decommit;

    /**
     * Unmap pages. Supplying this requires also supplying `memory_map`.
     * Must be thread-safe.
     */
    extern(C) void function(void*, size_t, size_t) memory_unmap;

    /**
     * Called after a system mapping failure. Return nonzero to retry or zero
     * to make the allocation return null.
     */
    extern(C) int function(size_t) map_fail_callback;

    /** Called when an allocator assertion fails, when assertions are enabled. */
    extern(C) void function(const(char)*) error_callback;
}

struct rpmalloc_config_t
{
    /** Page size, which must be a power of two; zero selects the OS default. */
    size_t page_size;

    /** Nonzero requests large or huge pages. */
    int enable_huge_pages;

    /** Nonzero requests transparent huge pages where supported. */
    int enable_thp;

    /** Set to one to keep unused pages committed. */
    int disable_decommit;

    /** Page mapping name on systems that support named anonymous regions. */
    const(char)* page_name;

    /** Huge-page mapping name on systems that support it. */
    const(char)* huge_page_name;

    /**
     * Set to one to unmap all allocator memory during finalization. This is
     * ignored when the native allocator is built with C-library overrides.
     */
    int unmap_on_finalize;
    version (linux)
        /** Disable transparent huge pages for the process on Linux. */
        int disable_thp;
    else version (Android)
        /** Disable transparent huge pages for the process on Android. */
        int disable_thp;
}

struct rpmalloc_heap_t
{
}

struct rpmalloc_heap_statistics_t
{
    /** Number of bytes allocated. */
    size_t allocated_size;
    /** Number of bytes committed. */
    size_t committed_size;
    /** Number of bytes mapped. */
    size_t mapped_size;
}

extern(C):

int rpmalloc_initialize(rpmalloc_interface_t* memory_interface);
int rpmalloc_initialize_config(
    rpmalloc_interface_t* memory_interface,
    rpmalloc_config_t* config);
const(rpmalloc_config_t)* rpmalloc_config();
void rpmalloc_finalize();

void rpmalloc_thread_initialize();
void rpmalloc_thread_finalize();
void rpmalloc_thread_collect();
int rpmalloc_is_thread_initialized();
void rpmalloc_thread_statistics(rpmalloc_thread_statistics_t* stats);
void rpmalloc_global_statistics(rpmalloc_global_statistics_t* stats);
void rpmalloc_dump_statistics(void* file);

void* rpmalloc(size_t size);
void* rpzalloc(size_t size);
void* rpcalloc(size_t count, size_t size);
void* rprealloc(void* pointer, size_t size);
void* rpaligned_realloc(
    void* pointer,
    size_t alignment,
    size_t size,
    size_t old_size,
    uint flags);
void* rpaligned_alloc(size_t alignment, size_t size);
void* rpaligned_zalloc(size_t alignment, size_t size);
void* rpaligned_calloc(size_t alignment, size_t count, size_t size);
void* rpmemalign(size_t alignment, size_t size);
int rpposix_memalign(void** result, size_t alignment, size_t size);
void rpfree(void* pointer);
size_t rpmalloc_usable_size(void* pointer);
void rpmalloc_linker_reference();

rpmalloc_heap_t* rpmalloc_heap_acquire();
void rpmalloc_heap_release(rpmalloc_heap_t* heap);
void* rpmalloc_heap_alloc(rpmalloc_heap_t* heap, size_t size);
void* rpmalloc_heap_aligned_alloc(
    rpmalloc_heap_t* heap,
    size_t alignment,
    size_t size);
void* rpmalloc_heap_aligned_zalloc(
    rpmalloc_heap_t* heap,
    size_t alignment,
    size_t size);
void* rpmalloc_heap_calloc(
    rpmalloc_heap_t* heap,
    size_t count,
    size_t size);
void* rpmalloc_heap_aligned_calloc(
    rpmalloc_heap_t* heap,
    size_t alignment,
    size_t count,
    size_t size);
void* rpmalloc_heap_realloc(
    rpmalloc_heap_t* heap,
    void* pointer,
    size_t size,
    uint flags);
void* rpmalloc_heap_aligned_realloc(
    rpmalloc_heap_t* heap,
    void* pointer,
    size_t alignment,
    size_t size,
    uint flags);
void rpmalloc_heap_free(rpmalloc_heap_t* heap, void* pointer);
void rpmalloc_heap_free_all(rpmalloc_heap_t* heap);
rpmalloc_heap_statistics_t rpmalloc_heap_statistics(rpmalloc_heap_t* heap);
void rpmalloc_heap_thread_set_current(rpmalloc_heap_t* heap);
rpmalloc_heap_t* rpmalloc_get_heap_for_ptr(void* pointer);

public:

alias VERSION = RPMALLOC_VERSION;
alias VERSION_MAJOR = RPMALLOC_VERSION_MAJOR;
alias VERSION_MINOR = RPMALLOC_VERSION_MINOR;
alias VERSION_PATCH = RPMALLOC_VERSION_PATCH;
alias VERSION_NUMBER = RPMALLOC_VERSION_NUMBER;
alias CACHE_LINE_SIZE = RPMALLOC_CACHE_LINE_SIZE;
alias MAX_ALIGNMENT = RPMALLOC_MAX_ALIGNMENT;
alias NO_PRESERVE = RPMALLOC_NO_PRESERVE;
alias GROW_OR_FAIL = RPMALLOC_GROW_OR_FAIL;

alias SpanUse = rpmalloc_span_use_t;
alias SizeUse = rpmalloc_size_use_t;
alias GlobalStatistics = rpmalloc_global_statistics_t;
alias ThreadStatistics = rpmalloc_thread_statistics_t;
alias MemoryInterface = rpmalloc_interface_t;
alias Config = rpmalloc_config_t;
alias Heap = rpmalloc_heap_t;
alias HeapStatistics = rpmalloc_heap_statistics_t;

/** Initialize the allocator with an optional custom memory interface. */
alias initialize = rpmalloc_initialize;

/** Initialize the allocator with an optional memory interface and configuration. */
alias initializeWithConfig = rpmalloc_initialize_config;

/** Get the allocator's current runtime configuration. */
alias currentConfig = rpmalloc_config;

/** Finalize the allocator. */
alias finalize = rpmalloc_finalize;

/** Initialize allocator state for the calling thread. */
alias initializeThread = rpmalloc_thread_initialize;

/** Finalize allocator state for the calling thread. */
alias finalizeThread = rpmalloc_thread_finalize;

/** Perform deferred deallocations pending for the calling thread's heap. */
alias collectThread = rpmalloc_thread_collect;

/** Return nonzero if the allocator is initialized for the calling thread. */
alias isThreadInitialized = rpmalloc_is_thread_initialized;

/** Get statistics for the calling thread. */
alias getThreadStatistics = rpmalloc_thread_statistics;

/** Get process-wide allocator statistics. */
alias getGlobalStatistics = rpmalloc_global_statistics;

/** Dump human-readable statistics to a C `FILE*`. */
alias dumpStatistics = rpmalloc_dump_statistics;

/** Allocate a memory block of at least the requested size. */
alias allocate = rpmalloc;

/** Allocate a zero-initialized block of at least the requested size. */
alias zeroAllocate = rpzalloc;

/** Allocate and zero-initialize space for `count` objects of `size` bytes. */
alias allocateArray = rpcalloc;

/** Reallocate a block to at least the requested size. */
alias reallocate = rprealloc;

/**
 * Reallocate with the requested size and alignment. Alignment must be a power
 * of two and a multiple of `void*.sizeof`, and should be smaller than a page.
 */
alias alignedReallocate = rpaligned_realloc;

/**
 * Allocate with the requested size and alignment. Alignment must be a power
 * of two and a multiple of `void*.sizeof`, and should be smaller than a page.
 */
alias alignedAllocate = rpaligned_alloc;

/** Allocate a zero-initialized block with the requested size and alignment. */
alias alignedZeroAllocate = rpaligned_zalloc;

/** Allocate and zero-initialize an aligned array. */
alias alignedAllocateArray = rpaligned_calloc;

/** Allocate a block with the requested size and alignment. */
alias memoryAlign = rpmemalign;

/** Store an aligned allocation in the supplied result pointer. */
alias posixMemoryAlign = rpposix_memalign;

/** Free an allocated memory block. */
alias free = rpfree;

/** Return the usable bytes from the pointer to the end of its allocation. */
alias usableSize = rpmalloc_usable_size;

/** Force inclusion of the native allocator object when required by a linker. */
alias forceLinkage = rpmalloc_linker_reference;

/**
 * Acquire a heap, reusing a released heap where possible. Heap operations are
 * not thread-safe: only one thread may use a given heap at a time.
 */
alias acquireHeap = rpmalloc_heap_acquire;

/**
 * Release a heap for reuse. This does not free its allocations; call
 * `freeAllFromHeap` first when that is required. A null pointer is permitted.
 */
alias releaseHeap = rpmalloc_heap_release;

/** Allocate a block of at least the requested size from a heap. */
alias allocateFromHeap = rpmalloc_heap_alloc;

/** Allocate an aligned block from a heap. */
alias alignedAllocateFromHeap = rpmalloc_heap_aligned_alloc;

/** Allocate a zero-initialized aligned block from a heap. */
alias alignedZeroAllocateFromHeap = rpmalloc_heap_aligned_zalloc;

/** Allocate and zero-initialize an array from a heap. */
alias allocateArrayFromHeap = rpmalloc_heap_calloc;

/** Allocate and zero-initialize an aligned array from a heap. */
alias alignedAllocateArrayFromHeap = rpmalloc_heap_aligned_calloc;

/** Reallocate a block that was allocated by the same heap. */
alias reallocateFromHeap = rpmalloc_heap_realloc;

/** Reallocate and align a block that was allocated by the same heap. */
alias alignedReallocateFromHeap = rpmalloc_heap_aligned_realloc;

/** Free a block that was allocated by the same heap. */
alias freeFromHeap = rpmalloc_heap_free;

/** Free all memory allocated by a heap. */
alias freeAllFromHeap = rpmalloc_heap_free_all;

/** Get heap statistics when statistics are enabled in the native build. */
alias getHeapStatistics = rpmalloc_heap_statistics;

/**
 * Make a heap current for the calling thread. A current heap must never be
 * shared between threads; the previous current heap is released for reuse.
 */
alias setCurrentThreadHeap = rpmalloc_heap_thread_set_current;

/** Return the heap on which a pointer was allocated. */
alias heapForPointer = rpmalloc_get_heap_for_ptr;
