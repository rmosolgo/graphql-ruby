# Autoresearch: Static Validation Pipeline Performance

## Objective
Optimize the entire static validation pipeline in graphql-ruby. The pipeline validates GraphQL queries against a schema before execution, checking field existence, argument compatibility, fragment usage, type correctness, and field mergeability.

The benchmark runs 5 different validation workloads:
- **introspection**: Introspection query against a card schema (~550µs)
- **abstract_frags**: Fragment-heavy query with abstract types (~270µs)
- **abstract_frags2**: Another abstract fragment query (~450µs)
- **big_query**: Large query against a big schema (~4ms)
- **fields_merge**: 5000 identical `hello` fields — tests FieldsWillMerge rule (~3.1s, 99.8% of total!)

## Metrics
- **Primary**: total_us (µs, lower is better) — sum of all 5 workload times
- **Secondary**: introspection_us, abstract_frags_us, abstract_frags2_us, big_query_us, fields_merge_us

## How to Run
`./autoresearch.sh` — outputs `METRIC name=number` lines.

## Files in Scope
- `lib/graphql/static_validation/rules/fields_will_merge.rb` — THE bottleneck (O(n²) field comparison)
- `lib/graphql/static_validation/base_visitor.rb` — AST visitor with validation hooks
- `lib/graphql/static_validation/interpreter_visitor.rb` — Includes all rules into visitor
- `lib/graphql/static_validation/validator.rb` — Entry point for validation
- `lib/graphql/static_validation/validation_context.rb` — Context passed to validators
- `lib/graphql/static_validation/definition_dependencies.rb` — Fragment dependency tracking
- `lib/graphql/static_validation/literal_validator.rb` — Input literal validation
- `lib/graphql/static_validation/all_rules.rb` — Rule ordering
- `lib/graphql/static_validation/rules/*.rb` — All individual validation rules
- `lib/graphql/language/static_visitor.rb` — Base AST visitor

## Off Limits
- Schema definition files (unless refactor needed to unlock perf)
- Benchmark files (except autoresearch.sh)
- Test files
- Parser/lexer

## Constraints
- Tests must pass: `./test_fast.sh`
- No new gem dependencies
- Validation must produce identical results (same errors for same inputs)
- Don't break public API

## What's Been Tried
1. **Deduplicate fields by signature in find_conflicts_within** — For fields with same response key, group by (name+definition+args) signature. Only compare across groups + one pair within. 143x speedup on pathological 5000-field case.
2. **Replace Array#& with intersect?** in mutually_exclusive? — avoids allocating intersection array.
3. **Eliminate redundant field lookups** — FieldsAreDefinedOnType was re-looking up field via types.field() when it was already in @field_definitions.last. RequiredArgumentsArePresent was calling types.arguments() twice.
4. **Flatten fragment spreads into single field map** (XING article approach) — Instead of 3-phase (fields-within, fields-vs-fragments, fragments-vs-fragments) with exponential recursive fragment cross-comparison, expand all fragment spreads inline into one flat field list. Eliminates find_conflicts_between_fragments/find_conflicts_between_fields_and_fragment entirely. 23% improvement on big_query.
5. **Caching fields_and_fragments_from_selection** — FAILED, `parents` parameter differs across calls for same node, affects mutually_exclusive? checks. Would need to separate raw field collection from parent tracking.

## Key Insights (Updated)
- Benchmark uses visibility profiles (production-like). Warden path matters less.
- `Visibility::Profile#field` is the costliest single operation (~7% of big_query time) — heavy caching internally but still involves multiple hash lookups + type checks per call
- `Visibility::Profile#initialize` creates ~12 Hash.new blocks per validation — ~4% overhead per query
- `Module#ancestors` is expensive and called from `ObjectMethods#get_field` for first-time field lookups
- The `deferred_spreads` array allocation in collect_fields_inner could be avoided
- `find_conflicts_within` with large same-key groups still does group_by which allocates

## Key Insights
- `fields_will_merge` is 99.8% of total time due to O(n²) `find_conflicts_within`
- With 5000 identical `hello` fields grouped under same response key, it does ~12.5M comparisons
- Each comparison in `find_conflict` checks field name equality, argument equality, return type conflicts, and recurses into sub-selections
- The `same_arguments?` method uses `Array#find` (O(n)) for each argument comparison
- `fields_and_fragments_from_selection` allocates Struct instances and arrays on every call
- `compared_fragments_key` builds strings with interpolation for cache keys
