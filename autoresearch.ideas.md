# Autoresearch Ideas

## Promising but deferred
- Cache fragment expansion results in collect_fields_inner — same fragment gets re-expanded in find_conflicts_between_sub_selection_sets with fresh visited_fragments each time. Would need to separate "raw fields" from "parents context"
- Visibility::Profile#initialize creates ~12 Hash.new per validation (~5%). Could schema cache/pool profiles?
- Visibility::Profile#load_all_types still called for some error paths (field not found on type uses `fields()` which may trigger loading). Could defer more aggressively
- DefinitionDependencies uses Set for tracking (4.5% total across init/resolve/on_fragment_spread) — could use plain Hash for speed
- Struct#initialize for Field — could use plain arrays [node, definition, owner_type, parents] to reduce allocation overhead
- `Visibility::Visit#visit_each` and `append_unvisited_type` are ~6% together — schema loading cost on each validation
- `return_types_conflict?` recursive type unwrapping — could compare type signatures as strings instead
