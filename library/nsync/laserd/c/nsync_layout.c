#include <nsync_cv.h>
#include <nsync_mu.h>

#include <stddef.h>

/*
 * Laser-D exposes the two public nsync synchronization objects by value.
 * Guard the reviewed 64-bit layout at native compile time on every platform.
 */
#define LASERD_NSYNC_LAYOUT_ASSERT(name, expression) \
	typedef char laserd_nsync_layout_##name[(expression) ? 1 : -1]

LASERD_NSYNC_LAYOUT_ASSERT(pointer_size, sizeof(void*) == 8);
LASERD_NSYNC_LAYOUT_ASSERT(mu_size, sizeof(nsync_mu) == 16);
LASERD_NSYNC_LAYOUT_ASSERT(mu_word_offset, offsetof(nsync_mu, word) == 0);
LASERD_NSYNC_LAYOUT_ASSERT(mu_waiters_offset, offsetof(nsync_mu, waiters) == 8);
LASERD_NSYNC_LAYOUT_ASSERT(cv_size, sizeof(nsync_cv) == 16);
LASERD_NSYNC_LAYOUT_ASSERT(cv_word_offset, offsetof(nsync_cv, word) == 0);
LASERD_NSYNC_LAYOUT_ASSERT(cv_waiters_offset, offsetof(nsync_cv, waiters) == 8);
