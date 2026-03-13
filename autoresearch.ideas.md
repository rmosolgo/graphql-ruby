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

## Done (in current branch)
- Profile#field result cache (owner, field_name) → visible field directly
- Profile#type result cache (type_name) → visible type directly  
- Wrapper#unwrap memoization — schema-level, benefits all queries
- NonNull/List to_type_signature memoization
- collect_fields_inner while loop
- Inline push_type
- Inline fragment path string deduplication

## Still promising
- Separate "raw field collection" from "parents context" to allow cache sharing between on_field and find_conflicts_between_sub_selection_sets paths (deep refactor)
- Reduce Field struct allocations — 2619 per validation, biggest single allocator
- Reduce response_keys array allocations — 879 `[field]` single-element arrays per validation
- Profile `preload` for named profiles — could pre-warm all caches
- Lazy path computation — @path push/pop happens for every visitor event but only read on errors
- `DefinitionDependencies` creates NodeWithPath objects for every fragment spread/definition — could be lazy
