# Autoresearch Ideas

## Tried and rejected
- Local field def cache in collect_fields_inner — double-caching over Profile
- Replace parents.dup+<< with [*parents, frag_type].freeze — slower due to splat
- DefinitionDependencies Set→Array — within noise
- Cache `referenced?` results per type_defn — within noise
- Replace all_references Set with Array — regression
- Defer array allocation for single-field response keys — hurts fields_merge
- Bulk while-loop conversion — YJIT handles .each blocks well, no clear win
- Eager return_type in Field struct — pays cost for all fields, no clear win
- Memoize Schema::Field#type for resolver_class path — breaks tests (resolver class mutable)
- Linked list / index-based @path (before stack→variable refactor) — same perf under YJIT
- Sentinel-based fetch in required_args_cache — within noise
- Reuse visited_fragments hash via clear — within noise

## Done (in current branch)
- FieldsWillMerge rewrite: flattened fragment collection, signature dedup, sub-field caching
- Profile#field and Profile#type result caches
- Wrapper#unwrap and to_type_signature memoization
- Skip empty iteration in visitor (args, directives, selections)
- Cache field_definition.type.unwrap per Schema::Field in visitor
- Replace Field Struct with plain class (1.7x faster init)
- Use @types/@fragments directly instead of context.types delegation
- Cache required argument names per field definition
- Replace ALL stacks with save/restore variables: @field_definitions, @directive_definitions, @argument_definitions, @object_types
- Replace @path push/pop with pre-allocated indexed array + depth counter
- Skip FieldsWillMerge conflict check for provably-safe selections
- Inline accessor method calls to direct ivar access
- Inline on_fragment_with_type to eliminate yield/block overhead

## Still promising
- **collect_fields_inner** — 12.7%, dominated by Profile#field lookups (7%) and Field object creation (1.3%). Could reduce Field creation count by lazy-creating only for multi-field response keys, but previous attempt regressed fields_merge.
- **GC pressure** — 4.6%, from Field objects, response_keys hashes. Consider reducing Hash allocation count.
- **Reduce Profile#field dispatch** — 7%, currently 2 hash lookups per call (outer by owner, inner by field_name). Could flatten to single hash with composite key.
