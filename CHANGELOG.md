# Changelog

### Breaking changes & deprecations

### New features

### Bug fixes


## 0.6.0 (14 Aug 2015)

### Breaking changes & deprecations

- Deprecate `params` option to `Query#new` in favor of `variables`
- Deprecated `.new { |obj, types, fields, args| }` API was removed (use `.define`)

### New features

- `Query#new` accepts `operation_name` argument
- `InterfaceType` and `UnionType` accept `resolve_type` configs

### Bug fixes

- Gracefully handle blank-string & whitespace-only queries
- Handle lists in variable definitions and arguments
- Handle non-null input types

## 0.5.0 (12 Aug 2015)

### Breaking changes & deprecations

- Deprecate definition API that yielded a bunch of helpers #18

### New features

- Add new definition API #18

### Bug fixes
