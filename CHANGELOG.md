# Changelog

### Breaking changes & deprecations

- Deprecate `params` option to `Query#new` in favor of `variables`
- Deprecated `.new { |obj, types, fields, args}` API was removed (use `.define`)

### New features

- `Query#new` accepts `operation_name` argument

### Bug fixes

- Gracefully handle blank-string & whitespace-only queries


## 0.5.0 (12 Aug 2015)

### Breaking changes & deprecations

- Deprecate definition API that yielded a bunch of helpers #18

### New features

- Add new definition API #18

### Bug fixes
