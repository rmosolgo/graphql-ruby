# Autoresearch Ideas — Static Validation Performance

## Tried and rejected
- Local field def cache in collect_fields_inner — double-caching over Profile
- Replace parents.dup+<< with [*parents, frag_type].freeze — slower due to splat
- DefinitionDependencies Set→Array — within noise
- Cache `referenced?` results per type_defn — within noise
- Replace all_references Set with Array — regression
- Bulk while-loop conversion — YJIT handles .each blocks well, no clear win
- Eager return_type in Field struct — pays cost for all fields, no clear win
- Memoize Schema::Field#type for resolver_class path — breaks tests (resolver class mutable)
- Linked list / index-based @path (before stack→variable refactor) — same perf under YJIT
- Sentinel-based fetch in required_args_cache — within noise
- Reuse visited_fragments hash via clear — within noise
- Cache single-element parent arrays per type + freeze — extra branching outweighs savings
- Cache selections_may_conflict? per selections array — hash overhead exceeds savings
- PendingField deferred definition lookup — extra is_a? branching costs more than saved
- Replace Forwardable in NodeWithPath — within noise
- Flatten Profile#field to single hash — array key hashing 5x slower than nested identity hash

## Remaining opportunities (diminishing returns)
- **collect_fields_inner** — 12.8% self-time, dominated by hash read/write (7.5%) and Field.new (1.4%). Fundamental to the algorithm.
- **GC pressure** — 4-5%, mostly from Field objects and response_keys hashes. Would need object pooling.
- **Merge on_field handler chain** — 7 method dispatches × 2247 fields = 15K super calls. Would require combining rule logic into single method, very invasive.
- **Reduce Field object count** — 2050 per validation, 85% never compared. But deferred creation adds branching cost that offsets savings.
