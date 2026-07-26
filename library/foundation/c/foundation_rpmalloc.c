#include "foundation_rpmalloc.h"

#include <foundation/foundation.h>
#include <rpmalloc.h>

#include <string.h>

static void*
laserd_foundation_allocate(hash_t context, size_t size, unsigned int align, unsigned int hint) {
	(void)context;

	if (hint & MEMORY_ZERO_INITIALIZED)
		return align ? rpaligned_zalloc(align, size) : rpzalloc(size);
	return align ? rpaligned_alloc(align, size) : rpmalloc(size);
}

static void*
laserd_foundation_reallocate(void* pointer, size_t size, unsigned int align, size_t oldsize, unsigned int hint) {
	void* result;

	if (align) {
		unsigned int flags = (hint & MEMORY_NO_PRESERVE) ? RPMALLOC_NO_PRESERVE : 0;
		result = rpaligned_realloc(pointer, align, size, oldsize, flags);
	} else {
		result = rprealloc(pointer, size);
	}

	if (result && (hint & MEMORY_ZERO_INITIALIZED) && (size > oldsize))
		memset((char*)result + oldsize, 0, size - oldsize);
	return result;
}

static bool
laserd_foundation_verify(const void* pointer) {
	(void)pointer;
	return true;
}

static size_t
laserd_foundation_usable_size(const void* pointer) {
	return rpmalloc_usable_size((void*)pointer);
}

static int
laserd_foundation_rpmalloc_initialize(void) {
	return rpmalloc_initialize(0);
}

static void
laserd_foundation_rpmalloc_finalize(void) {
	rpmalloc_finalize();
}

static memory_system_t
laserd_foundation_rpmalloc_system(void) {
	memory_system_t memory;
	memset(&memory, 0, sizeof(memory));
	memory.allocate = laserd_foundation_allocate;
	memory.reallocate = laserd_foundation_reallocate;
	memory.deallocate = rpfree;
	memory.usable_size = laserd_foundation_usable_size;
	memory.verify = laserd_foundation_verify;
	memory.thread_initialize = rpmalloc_thread_initialize;
	memory.thread_finalize = rpmalloc_thread_finalize;
	memory.initialize = laserd_foundation_rpmalloc_initialize;
	memory.finalize = laserd_foundation_rpmalloc_finalize;
	return memory;
}

int
laserd_foundation_initialize_rpmalloc(void) {
	static const char application_name[] = "Laser-D application";
	static const char application_short_name[] = "laserd";
	application_t application;
	foundation_config_t config;

	if (foundation_is_initialized())
		return 0;

	memset(&application, 0, sizeof(application));
	application.name = string_const(application_name, sizeof(application_name) - 1);
	application.short_name = string_const(application_short_name, sizeof(application_short_name) - 1);

	memset(&config, 0, sizeof(config));
	return foundation_initialize(laserd_foundation_rpmalloc_system(), application, config);
}

void
laserd_foundation_finalize(void) {
	foundation_finalize();
}

int
laserd_foundation_is_initialized(void) {
	return foundation_is_initialized() ? 1 : 0;
}
