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
(Nothing yet — baseline run pending)

## Key Insights
- `fields_will_merge` is 99.8% of total time due to O(n²) `find_conflicts_within`
- With 5000 identical `hello` fields grouped under same response key, it does ~12.5M comparisons
- Each comparison in `find_conflict` checks field name equality, argument equality, return type conflicts, and recurses into sub-selections
- The `same_arguments?` method uses `Array#find` (O(n)) for each argument comparison
- `fields_and_fragments_from_selection` allocates Struct instances and arrays on every call
- `compared_fragments_key` builds strings with interpolation for cache keys
