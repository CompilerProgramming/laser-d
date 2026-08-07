// TEST_MODE: compilable
// COMPILE_SEPARATELY:
// EXTRA_SOURCES: extra-files/package_visibility/inner/source.d extra-files/package_visibility/inner/peer.d extra-files/package_visibility/inner/sub/child.d extra-files/package_visibility/outer_peer.d
// REQUIRED_ARGS: -Ilaser-d/extra-files

module package_visibility_accepted;

import package_visibility.inner.peer;
import package_visibility.inner.sub.child;
import package_visibility.outer_peer;

static assert(innerPeerValue == 36);
static assert(descendantValue == 36);
static assert(outerPeerValue == 19);
