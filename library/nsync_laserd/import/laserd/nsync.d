/**
 * Laser-D bindings for nsync 1.30.0 mutexes and condition variables.
 *
 * Both types are valid when zero initialized. They are intentionally exposed
 * by value because their 64-bit C ABI is guarded by native static assertions.
 */
module laserd.nsync;

struct nsync_mu
{
    private uint word;
    private uint padding;
    private void* waiters;
}

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

void nsync_mu_init(nsync_mu* mutex);
void nsync_mu_lock(nsync_mu* mutex);
void nsync_mu_unlock(nsync_mu* mutex);
int nsync_mu_trylock(nsync_mu* mutex);
void nsync_mu_rlock(nsync_mu* mutex);
void nsync_mu_runlock(nsync_mu* mutex);
int nsync_mu_rtrylock(nsync_mu* mutex);
void nsync_mu_assert_held(const(nsync_mu)* mutex);
void nsync_mu_rassert_held(const(nsync_mu)* mutex);
int nsync_mu_is_reader(const(nsync_mu)* mutex);

void nsync_cv_init(nsync_cv* condition);
void nsync_cv_signal(nsync_cv* condition);
void nsync_cv_broadcast(nsync_cv* condition);
void nsync_cv_wait(nsync_cv* condition, nsync_mu* mutex);
