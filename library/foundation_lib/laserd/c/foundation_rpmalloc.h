#ifndef LASERD_FOUNDATION_RPMALLOC_H
#define LASERD_FOUNDATION_RPMALLOC_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Initialize Foundation with rpmalloc as its memory system.
 *
 * The function is idempotent. A successful call owns the process-wide
 * rpmalloc instance until laserd_foundation_finalize is called.
 */
int
laserd_foundation_initialize_rpmalloc(void);

/*
 * Finalize Foundation and the rpmalloc instance owned by it.
 *
 * Calling this function while Foundation is not initialized is harmless.
 */
void
laserd_foundation_finalize(void);

/* Return non-zero while Foundation is initialized. */
int
laserd_foundation_is_initialized(void);

#ifdef __cplusplus
}
#endif

#endif
