/**
 * Laser-D bindings for rpmalloc 2.0.1.
 *
 * The native library is built without process-wide malloc replacement and
 * with the first-class heap API enabled.
 */
module laserd.rpmalloc;

import core.stdc.stddef : size_t;

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
    extern(C) void* function(size_t, size_t, size_t*, size_t*) memory_map;
    extern(C) int function(void*, size_t) memory_commit;
    extern(C) int function(void*, size_t) memory_decommit;
    extern(C) void function(void*, size_t, size_t) memory_unmap;
    extern(C) int function(size_t) map_fail_callback;
    extern(C) void function(const(char)*) error_callback;
}

struct rpmalloc_config_t
{
    size_t page_size;
    int enable_huge_pages;
    int enable_thp;
    int disable_decommit;
    const(char)* page_name;
    const(char)* huge_page_name;
    int unmap_on_finalize;
    version (linux)
        int disable_thp;
    else version (Android)
        int disable_thp;
}

struct rpmalloc_heap_t
{
}

struct rpmalloc_heap_statistics_t
{
    size_t allocated_size;
    size_t committed_size;
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
