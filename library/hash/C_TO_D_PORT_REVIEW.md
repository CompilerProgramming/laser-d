# Porting review: `st.c` (Ruby) → `laserd.hash`

A comparison of the C hash table in `st-hash/` (Vladimir Makarov's redesign of
Ruby's `st.c`) against the Laser-D port in
[`import/laserd/hash.d`](import/laserd/hash.d).

The goal of this document is narrow: **what behaviour and machinery from the C
original did not survive the port, and what the practical consequence of each
loss is.** It is not a bug report against the D code — the port is faithful for
its intended use — but a record of the deltas so that future callers understand
the guarantees they no longer have.

Sources reviewed:

- C: `st-hash/st.c` (2176 lines), `st-hash/st.h`, `st-hash/test_st.c`
- D: [`import/laserd/hash.d`](import/laserd/hash.d) (1062 lines),
  [`test/hash_test.d`](test/hash_test.d)
- Laser-D language constraints:
  `spec-markdown/d-compatibility.md`, `spec-markdown/portability.md`

---

## Summary

The port preserves the *data structure* faithfully: the array-of-entries +
open-addressed bins layout, insertion-order iteration, the 8/16/32/64-bit bin
packing, the deleted-entry/deleted-bin sentinels, the secondary-hash probe
sequence, compaction-vs-reallocation on rebuild, and the full public operation
set (`lookup`, `insert`, `insert2`, `delete`, `shift`, `update`, `foreach`,
`keys`/`values`, `copy`, `clear`). The storage-representation test
([`test/hash_test.d:45`](test/hash_test.d)) confirms the on-heap layout matches
the C feature table byte-for-byte.

What was lost falls into five buckets, roughly in order of practical importance:

| # | Lost | Consequence | Severity |
|---|------|-------------|----------|
| 1 | Reentrancy / rebuild-during-callback safety (the whole `retry` machinery) | Custom hash/compare callbacks that mutate the table, and insertion during `foreach`, are no longer memory-safe | High (for custom callbacks); none for the shipped types |
| 2 | Numeric hash bit-mixing (`st_numhash`) → replaced by identity | Pointer-like / high-bit-entropy keys cluster into few bins; probe chains degrade | Medium–High for a compiler hashing pointers |
| 3 | MurmurHash3 string hash + word-at-a-time core → byte-at-a-time FNV-1a | Different (Ruby-incompatible) hash values; slower on long keys; the incremental `st_hash_*` API is now an ad-hoc mix | Low–Medium |
| 4 | Micro-optimizations: prefetch, branch hints, CLZ intrinsic, single-pass insert probe, precomputed feature table | Constant-factor throughput only | Low |
| 5 | Dropped API surface + all debug assertions | Embedded-table init, `st_replace`, stats, and every invariant check are gone | Low |

Two things were *gained* and are worth noting for balance: an explicit
integer-overflow guard on allocation size
([`hash.d:309` `valid_storage_size`](import/laserd/hash.d)), and an `ST_ERROR`
return path on allocation failure from `insert`/`add_direct`/`rebuild` where the
C code would malloc-fail into a NULL deref. The port is more robust under OOM.

---

## 1. Reentrancy: the rebuild-during-callback machinery (largest loss)

### What C does

The single largest subsystem in `st.c` exists to tolerate the table being
**rebuilt underneath an in-progress operation**. In Ruby the `hash` and
`compare` callbacks can be Ruby code; a thread switch or GC during a callback
can trigger a rebuild that reallocates and frees `tab->entries`. To survive
this, every search records the rebuild counter and reports a special sentinel
if it changed mid-comparison:

```c
#define DO_PTR_EQUAL_CHECK(tab, ptr, hash_val, key, res, rebuilt_p) \
    do {                                                            \
        unsigned int _old_rebuilds_num = (tab)->rebuilds_num;       \
        res = PTR_EQUAL(tab, ptr, hash_val, key);                   \
        rebuilt_p = _old_rebuilds_num != (tab)->rebuilds_num;       \
    } while (false)
```

Every public entry point (`st_lookup`, `st_insert`, `st_general_delete`,
`st_shift`, `st_update`, `st_general_foreach`) is wrapped in a `retry:` /
`goto retry` loop that re-reads `tab->entries` and restarts when a search
returns `REBUILT_TABLE_ENTRY_IND` / `REBUILT_TABLE_BIN_IND`
(`st.c:914`, `1073`, `1139`, `1628`). `st_general_foreach` goes further: after
each callback it compares `rebuilds_num` and, if it changed, **re-finds the
current entry by key** so that iteration continues correctly even after the
entry array was moved (`st.c:1628-1651`).

### What D does

All of it is gone. `do_hash`/`keys_equal` call the callbacks directly
([`hash.d:84`](import/laserd/hash.d), [`hash.d:89`](import/laserd/hash.d)), and
every search holds a raw `st_table_entry*` into `table.entries` across the
comparison, e.g.:

```d
const(st_table_entry)* entry = &table.entries[index];
if (entry.hash == hash && keys_equal(table, entry.key, key))  // hash.d:215
```

There is no rebuild counter check, no `retry`, and no re-find in `st_foreach`
([`hash.d:811`](import/laserd/hash.d)).

### Consequence

- **For the three built-in types (`num`, `str`, `strcase`) there is no
  consequence.** Their comparators (`numeric_compare`, `string_compare`,
  `string_case_compare`) are leaf `extern(C)` functions that never touch the
  table, so a rebuild can never occur inside a comparison. Every shipped test
  passes and is safe.
- **For a caller-supplied `st_hash_type` whose callback re-enters the table**
  (inserts/deletes, directly or by triggering a rebuild), the port is
  **memory-unsafe**: the cached `entry`/`index` dangles after `table.entries`
  is freed and reallocated by `rebuild`. C handled this; D corrupts memory.
- **Insertion during `st_foreach` is no longer safe.** C explicitly supports
  mutating the table while traversing (its header comment and the re-find logic
  are built for it). In D, if a `foreach` callback inserts enough to trigger a
  rebuild, the loop's `index` no longer maps to the same entry after compaction,
  and the `entry` pointer captured before the callback dangles on the
  `ST_DELETE`/`ST_REPLACE` paths ([`hash.d:879-909`](import/laserd/hash.d)).
  *Deletion* during `foreach` remains safe, because `st_delete` never
  reallocates — so the common "delete-while-iterating" pattern (exercised by
  `delete_even` in the test) is fine.

### Note on why part of this was unavoidable

Laser-D has **no runtime `assert`** (`d-compatibility.md` §"Expressions"). C's
`st_update` guards the callback with
`assert(rebuilds_num == tab->rebuilds_num)` (`st.c:1560`) — i.e. C *also*
refuses to support a rebuild inside an `update` callback, but at least traps it
in debug builds. That safety net cannot be expressed in Laser-D, so the port
silently proceeds where C would abort. This is a language constraint, not an
oversight, but the net effect is less debuggability.

**Recommendation:** document in the module header that hash/compare/update/
foreach callbacks must not mutate the table (no reentrancy), converting an
undocumented behavioural change into a stated contract.

---

## 2. Numeric hash downgraded to identity

### What changed

C mixes the bits of a numeric key:

```c
st_index_t st_numhash(st_data_t n) {          // st.c:2169
    enum {s1 = 11, s2 = 3};
    return (st_index_t)((n>>s1 | (n<<s2)) ^ (n>>s2));
}
```

D returns the key unchanged:

```d
private extern(C) st_index_t numeric_hash(st_data_t value) {  // hash.d:462
    return value;
}
```

The public `st_numhash` ([`hash.d:1018`](import/laserd/hash.d)) inherits the
identity behaviour too, so even the exposed helper differs from C.

### Consequence

The initial bin is chosen by `hash & (bins_count - 1)` — i.e. only the **low**
bits of the hash. Makarov mixes high bits down specifically because raw keys
often carry their entropy in the high bits and have degenerate low bits:

- **Aligned pointers** (8- or 16-byte aligned object/symbol addresses) have
  constant low 3–4 bits. Under identity hashing they map to only every 8th or
  16th bin, wasting 7/8–15/16 of the bin array and forming long secondary-probe
  chains. This is the exact case Ruby's mixing defends against, and the exact
  case a compiler hashing `Symbol*` / node pointers hits.
- **Keys differing only in high bits** collide in the same initial bin.

Probing still resolves correctness (the secondary hash perturbs with the full
key, so lookups return the right answer), so this is a **performance / load
distribution** regression, not a correctness bug. For dense small-integer keys
(the test's `0..1000`) identity hashing is actually optimal, which is why the
tests don't reveal it. The risk is real precisely for the pointer-keyed tables
a Laser-D compiler is likely to build.

**Recommendation:** port `st_numhash`'s mixing verbatim — it is three shifts and
two xors, `@nogc`/`nothrow`-clean, and has no language obstacle.

---

## 3. String hashing: algorithm and the incremental API changed

### What changed

- C `strhash` uses `st_hash()` — a **word-at-a-time simplified MurmurHash3**
  with an unaligned-access fast path and per-arch rotate constants
  (`st.c:1890-2033`), seeded with `FNV1_32A_INIT`.
- C `strcasehash` uses a separate **32-bit FNV-1a** (`st.c:2143`).
- D uses one routine, **64-bit FNV-1a**, byte-at-a-time, for both
  (`hash_bytes`, [`hash.d:499`](import/laserd/hash.d)), with a `fold_case` flag.

The standalone incremental API was also re-based onto FNV:

| Function | C (`st.c`) | D (`hash.d`) |
|----------|-----------|--------------|
| `st_hash` | word-at-a-time MurmurHash3 | byte loop FNV-1a (`:1023`) |
| `st_hash_uint32` | `murmur_step(h, i)` | FNV over 4 bytes (`:1043`) |
| `st_hash_uint` | `murmur_step`-based | FNV over 8 bytes (`:1048`) |
| `st_hash_end` | `murmur_finish` (Mix13 constants `0xbf58476d…`) | MurmurHash3 `fmix64` (`0xff51afd7…`) (`:1053`) |

### Consequence

- **Hash values are not Ruby-compatible** and the incremental building blocks no
  longer compose into a named published hash: `st_hash_start` → FNV steps →
  `st_hash_end` (a *Murmur* finalizer) is a bespoke construction. Anything that
  expected `st.c` values (persistence, cross-checking, shared fixtures) breaks.
  For a self-contained in-memory table this is harmless.
- **Throughput on long keys is lower**: byte-at-a-time with a
  multiply-per-byte, versus C's 8-bytes-per-step core with an alignment fast
  path. For short keys (identifiers) the difference is negligible.
- **Distribution is fine** — FNV-1a is a reasonable general-purpose hash, and
  `normalize_hash` handles the reserved value. No correctness concern.

This is a defensible simplification (portable, no unaligned-access or
endianness machinery, which `portability.md` would otherwise require care for).
Worth flagging only so the divergence from Ruby's values is a conscious,
documented choice rather than an accident.

---

## 4. Micro-optimizations dropped (constant-factor only)

None of these affect correctness or asymptotics; they are the throughput margin
the "40% faster" claim in Makarov's comment (`st.c:98`) was built on.

- **`PREFETCH` / `EXPECT` branch hints** (`st.c:854-855`, and every `EXPECT`
  around rebuild/rare paths) — gone; no Laser-D equivalent is used.
- **CLZ intrinsic in `get_power2`.** C computes the power with a
  count-leading-zeros intrinsic (`nlz_int64`, `st.c:342`). D uses a shift-and-
  compare loop ([`hash.d:97`](import/laserd/hash.d)). Same result, up to ~62
  iterations instead of one instruction — but only on table creation/rebuild, so
  immaterial.
- **Single-pass find-and-reserve on insert.** C's
  `find_table_bin_ptr_and_reserve` (`st.c:1073`) walks the probe chain **once**,
  simultaneously checking for an existing key and reserving the insertion bin
  (reusing a deleted bin if seen). D walks the chain **twice** on a new-key
  insert: `find_entry_index` then `find_insertion_bin`
  ([`hash.d:606`, `hash.d:623`](import/laserd/hash.d)). Correct, but roughly
  doubles probe work on the insert-miss path.
- **Precomputed `features[]` table** (`st.c:205`) replaced by computing
  `bin_power = power + 1` and `size_ind`/`bins_size` on demand
  ([`hash.d:298`, `hash.d:121`, `hash.d:148`](import/laserd/hash.d)). Verified
  equivalent by the layout test. A Laser-D `immutable` table was possible but
  the computed form is cleaner and just as correct.

---

## 5. Dropped API surface and debug instrumentation

- **Embedded / caller-storage table variants** are not ported:
  `st_init_existing_table_with_size`, `st_init_existing_numtable_with_size`,
  `st_init_existing_strtable_with_size`, `st_free_embedded_table`,
  `st_replace`, and `rb_st_add_direct_with_hash` (`st.c:579-618`, `732`,
  `1271`, `1340`). D always heap-allocates the `st_table` header itself
  (`allocate_table`, [`hash.d:411`](import/laserd/hash.d)). Mild irony: Laser-D
  favours caller-provided storage, yet the one API that offered it was dropped.
  Consequence: you cannot place an `st_table` in caller memory (e.g. inline in
  another struct) and init it in place.
- **`HASH_LOG` collision statistics** (`st.c:551-576`, `768-790`) — profiling
  aid, gone.
- **`ST_INIT_VAL` debug fill pattern** (`st.c:167`) and **every `assert`** —
  gone, partly forced (no runtime `assert` in Laser-D). The invariant checks in
  `rebuild_table_with` and `st_update` no longer trap violations.
- **Signature drift:** `st_add_direct` returns `int` in D
  ([`hash.d:659`](import/laserd/hash.d)) but `void` in C/`st.h`
  (`st.c:1281`) — a deliberate change to surface `ST_ERROR`, but an ABI/source
  incompatibility with the published header. All entry points also gained the
  `rpmalloc_heap_t*` parameter, which is the intended design of the port.

---

## Verdict

The port is **correct and safe for the workloads its tests cover and for any
use with the three built-in hash types.** The structural fidelity is high and
the data layout is provably identical.

The losses that actually matter for a compiler runtime, in priority order:

1. **Restore `st_numhash`'s bit-mixing** (§2) — cheapest fix, largest real-world
   payoff, directly relevant to pointer-keyed tables.
2. **Document the no-reentrancy contract** (§1) — the safety machinery is
   reasonable to drop for non-reentrant `extern(C)` comparators, but the removed
   guarantee (esp. *insert-during-`foreach`*) should be stated, not implied.
3. Everything else (§3–§5) is a conscious simplification or a constant-factor
   cost that is fine to leave as-is, provided the Ruby-incompatible hash values
   (§3) and the single dropped in-place-init capability (§5) are known.
