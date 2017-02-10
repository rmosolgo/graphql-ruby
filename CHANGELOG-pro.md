# graphql-pro

### Breaking Changes

### Deprecations

### New Features

### Bug Fix

## 1.1.0 (9 Feb 2017)

### New Features

- Add AppSignal monitoring platform
- Add type- and field-level opting in and opting out of monitoring
- Add `monitor_scalars: false` to skip monitoring on scalars

### Bug Fixes

- Fix `OrderedRelationConnection` when neither `first` nor `last` are provided (use `max_page_size` or don't limit)

## 1.0.4 (23 Jan 2017)

### Bug Fixes

- `OrderedRelationConnection` exposes more metadata methods: `parent`, `field`, `arguments`, `max_page_size`, `first`, `after`, `last`, `before`

## 1.0.3 (23 Jan 2017)

### Bug Fixes

- When an authorization check fails on a non-null field, propagate the null and add a response to the errors key (as if the field had returned null). It previously leaked the internal symbol `__graphql_pro_access_not_allowed__`.
- Apply a custom Pundit policy even when the value isn't `nil`. (It previously fell back to `Pundit.policy`, skipping a `pundit_policy_name` configuration.)

## 1.0.2

### Bug Fixes

- `OrderedRelationConnection` exposes the underlying relation as `#nodes` (like `RelationConnection` does), supporting custom connection fields.

## 1.0.1

### New Features

- CanCan integration now supports a custom `Ability` class with the `ability_class:` option:

  ```ruby
  authorize :cancan, ability_class: CustomAbility
  ```

## 1.0.0

- `GraphQL::Pro` released
