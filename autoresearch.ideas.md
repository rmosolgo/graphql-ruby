# Autoresearch Ideas

## Tried and rejected
- ~~Local field def cache in collect_fields_inner~~ — double-caching over Profile, within noise
- ~~Replace parents.dup+<< with [*parents, frag_type].freeze~~ — slower due to splat allocation
- ~~DefinitionDependencies Set→Array~~ — within noise, not worth the risk
- ~~Cache `referenced?` results per type_defn~~ — within noise, each type only checked once
- ~~Replace all_references Set with Array~~ — regression, duplicates increase iteration cost
- ~~Cache final field() result~~ — double-caching over internal hashes

## Promising but deferred
- Cache fragment expansion results in collect_fields_inner — same fragment gets re-expanded in find_conflicts_between_sub_selection_sets with fresh visited_fragments each time. Would need to separate "raw fields" from "parents context"
- Unify the two collect_fields paths (parents:[] from on_field vs parents:[type] from sub_selection) to share cache — failed because mutually_exclusive? depends on parents length, need careful restructuring
- Visibility::Profile#initialize creates ~12 Hash.new per validation (~5%) — but most of the cost is actually lazy default proc execution, not hash creation. Not easily optimizable.
- `ObjectMethods#get_field` (6.2% total) calls `ancestors`, `visible_interface_implementation?` — cached per (type, field_name) pair but many distinct pairs in large queries
- Try moving `conflicts_within_selection_set` AFTER super in on_field — would let visitor resolve field defs first, but collect_fields_inner walks AST directly so wouldn't help
- Reduce GC pressure (6.2%) by reducing Field struct creation — could use [node, defn, type, parents] arrays but YJIT likely handles Struct well
