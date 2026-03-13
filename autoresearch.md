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
- Benchmark uses YJIT + visibility profiles + did_you_mean(nil) + allow_legacy_invalid_return_type_conflicts(false) to match production
- Primary metric now includes large_query (36KB checkout query against 31K-line schema) — most representative
- `Visibility::Profile#field` is ~9% of large_query time. Profile caches internally, double-caching doesn't help.
- `Visibility::Profile#initialize` creates ~12 Hash.new per validation (~5%)
- `collect_fields_inner` is ~7% — Field struct creation + field lookups + parents array copies
- `FieldsWillMergeError#add_conflict` used expensive `AbstractNode#==` for dedup — fixed with identity check
- `FragmentTypesExist` was loading ALL types just to build did_you_mean dictionary even when did_you_mean disabled — fixed
- Small benchmarks (abstract_frags ~550µs) have high variance, not useful for detecting small improvements

## Key Insights
- `fields_will_merge` is 99.8% of total time due to O(n²) `find_conflicts_within`
- With 5000 identical `hello` fields grouped under same response key, it does ~12.5M comparisons
- Each comparison in `find_conflict` checks field name equality, argument equality, return type conflicts, and recurses into sub-selections
- The `same_arguments?` method uses `Array#find` (O(n)) for each argument comparison
- `fields_and_fragments_from_selection` allocates Struct instances and arrays on every call
- `compared_fragments_key` builds strings with interpolation for cache keys
