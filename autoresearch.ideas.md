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
- Memoize Schema::Field#type for resolver_class path — resolver class can be mutated after field creation; would break tests
- Linked list for @path — creates MORE allocations than push/pop
- Index-based @path (fixed array) — same performance as push/pop under YJIT

## Done (in current branch)
- Profile#field result cache (owner, field_name) → visible field directly
- Profile#type result cache (type_name) → visible type directly  
- Wrapper#unwrap memoization — schema-level, benefits all queries
- NonNull/List to_type_signature memoization
- collect_fields_inner while loop
- Inline push_type
- Inline fragment path string deduplication
- Skip empty iteration in visitor (args, directives, selections)
- Cache field_definition.type.unwrap per Schema::Field in visitor
- Replace Field Struct with plain class (1.7x faster init)
- Use @types/@fragments directly instead of context.types delegation

## Still promising
- Separate "raw field collection" from "parents context" to allow cache sharing between on_field and find_conflicts_between_sub_selection_sets paths (deep refactor)
- Lazy path computation — @path push/pop happens for every visitor event but only read on errors (~3.5% of time across all stacks)
- Cache the "required arguments" result per field definition (avoid re-iterating args on every field visit)
- Merge on_field handler chain — currently 6-7 separate on_field methods chained via super; could combine hot-path checks into fewer methods
- Consider whether `on_field` in FieldsWillMerge can share collect_fields results with operation-level check
