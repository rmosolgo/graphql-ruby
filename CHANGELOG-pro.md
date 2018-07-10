# graphql-pro

### Breaking Changes

### Deprecations

### New Features

### Bug Fix

## 1.7.8 (10 July 2018)

- Authorization: fix scoping lists of abstract type when there's no `#scope` method on the strategy

## 1.7.7 (10 May 2018)

### Bug Fix

- Fix ordering of authorization field instrumenter (put it at the end, not the beginning of the list)

## 1.7.6 (2 May 2018)

### New Features

- Authorization: Add `view`/`access`/`authorize` methods to `GraphQL::Schema::Mutation`

## 1.7.5 (19 Apr 2018)

### New Features

- Authorization: when a `fallback:` configuration is given, apply it to each field which doesn't have a configuration of its own or from its return type. _Don't_ apply that configuration at schema level (it's applied to each otherwise uncovered field instead).

## 1.7.4 (16 Apr 2018)

### New Features

- Support Mongoid::Criteria in authorization scoping

## 1.7.3 (12 Apr 2018)

### Bug Fix

- Fix authorization code for when `ActiveRecord` is not defined

## 1.7.2 (10 Apr 2018)

### Bug Fix

- Use a more permissive regexp (`/^\s*((?:[a-z._]+)\(.*\))\s*(asc|desc)?\s*$/im`) to parse SQL functions

## 1.7.1 (4 Apr 2018)

### Bug Fix

- Fix route helpers to support class-based schemas

## 1.7.0 (25 Mar 2018)

### New Features

- Support `1.8-pre` versions of GraphQL-Ruby

### Bug Fix

- Fix OperationStore when other query instrumenters need `.query_string`

## 1.6.5 (7 Feb 2018)

### Bug Fix

- Support `LEAST(...)` in stable cursors

## 1.6.4 (7 Feb 2018)

### Bug Fix

- Support `CASE ... END` in stable cursors

## 1.6.3 (26 Jan 2018)

### Bug Fix

- Support `FIELD(...)` in stable cursors

## 1.6.2 (13 Jan 2018)

### Bug Fix

- Improve detection of `OperationStore` for the dashboard
- Serve `Content-Type` and `Content-Length` headers with dashboard pages
- Better `Dashboard#inspect` for Rails routes output
- Use a string to apply order-by-primary-key for better Rails 3 support

## 1.6.1 (22 Nov 2017)

### New Features

- Support `composite_primary_keys` gem

## 1.6.0 (13 Nov 2017)

### Breaking Changes

- `GraphQL::Pro::UI` renamed to `GraphQL::Pro::Dashboard`

### Deprecations

- Routing method `.ui` was renamed to `.dashboard`

### New Features

- Added `GraphQL::Pro::Subscriptions`
- Added subscriptions component to Dashboard

## 1.5.9 (10 Oct 2017)

### Bug Fix

- Don't crash when scoping lists of abstract types with Pundit

## 1.5.8 (2 Oct 2017)

### New Features

- Use `authorize(:pundit, namespace: )` to lookup policies in a namespace instead of the global namespace.

### Bug Fix

- Introspection data is allowed through `fallback:` `authorize:` and `access:` filters. (It can be hidden with a `view:` filter.)

## 1.5.7 (20 Sept 2017)

### Bug Fix

- Properly return `nil` when a list of authorized objects returns `nil`

## 1.5.6 (19 Sept 2017)

### New Features

- Add `authorization(..., operation_store:)` option for authorizing operation store requests

## 1.5.5 (18 Sept 2017)

### New Features

- Support `ConnectionType.bidrectional_pagination?` in stable RelationConnection

## 1.5.4 (18 Sept 2017)

### Bug Fix

- Fix load issue when Rails is not present

## 1.5.3 (4 Sept 2017)

### Bug Fix

- Fix OperationStore views on PostgresQL
- Fix stable cursors when joined tables have the same column names

  __Note:__ This is implemented by adding extra fields to the `SELECT`
  clause with aliases like `cursor_#{idx}`, so you'll notice this in your
  SQL logs.

## 1.5.2 (4 Aug 2017)

### Bug Fix

- Bump `graphql` dependency to `1.6`

## 1.5.1 (2 Aug 2017)

### New Features

- Routing extensions moved to `using GraphQL::Pro::Routes`

### Deprecations

- Deprecate `using GraphQL::Pro`, move extensions to `GraphQL::Pro::Routes`

## 1.5.0 (31 Jul 2017)

### New Features

- Add `GraphQL::Pro::OperationStore` for persisted queries with Rails

## 1.4.8 (14 Jul 2017)

### Bug Fix

- Update `authorization` to use type-level `resolve_type` hooks

## 1.4.7 (13 Jul 2017)

### Bug Fix

- Update authorization instrumentation for `graphql >= 1.6.5`

## 1.4.6 (6 Jul 2017)

### Bug Fix

- Fix typo in RelationConnection source

## 1.4.5 (6 Jul 2017)

### Bug Fix

- Correctly fall back to offset-based cursors with `before:` argument

## 1.4.4 (15 Jun 2017)

### New Features

- Add `Schema#unauthorized_object(obj, ctx)` hook for failed runtime checks

### Bug Fix

- Prevent usage of `parent_role:` with `view:` or `access:` (since parent role requires a runtime check)
- Fix versioned, encrypted cursors with 16-byte legacy cursors

## 1.4.3 (13 Jun 2017)

### New Features

- `OrderedRelationConnection` supports ordering by joined fields

### Bug Fix

- Update auth plugin for new Relay instrumenters
- `Pro::Encoder` supports `encoder(...)` as documented

## 1.4.2 (2 May 2017)

### Bug Fix

- Fix compatibility of `RelationConnection` and `RangeAdd` helper

## 1.4.1 (19 Apr 2017)

### New Features

- Add `:datadog` monitoring

## 1.4.0 (19 Apr 2017)

### New Features

- `ActiveRecord::Relation`s can be scoped by Pundit `Scope`s, CanCan `accessible_by`, or custom strategy's `#scope(gate, relation)` methods
- Default authorization configuration can be provided with `authorization(..., fallback: { ... })`
- Authorization's `:current_user` key can be customized with `authorization(..., current_user: ...)`

## 1.3.0 (7 Mar 2017)

### New Features

- Serve static, persisted queries with `GraphQL::Pro::Repository`

## 1.2.3 (2 May 2017)

### Bug Fix

- Fix compatibility of `RelationConnection` and `RangeAdd` helper

## 1.2.2 (6 Mar 2017)

### Bug Fix

- Raise `GraphQL::Pro::RelationConnection::InvalidRelationError` when a grouped, unordered relation is returned from a field. (This relation can't be stably paginated.)

## 1.2.1 (3 Mar 2017)

### New Features

- Formally support ActiveRecord `>= 4.1.0`

### Bug Fix

- Support grouped relations in `GraphQL::Pro::RelationConnection`

## 1.2.0 (1 Mar 2017)

### New Features

- Authorize fields based on their parent object, for example:

  ```ruby
  AccountType = GraphQL::ObjectType.define do
    name "Account"
    # This field is visible to all users:
    field :name, types.String
    # This is only visible when the current user is an `:owner`
    # of this account
    field :account_balance, types.Int, authorize: { parent_role: :owner }
  end
  ```

## 1.1.1 (22 Feb 2017)

### Bug Fixes

- Fix monitoring when `Query#selected_operation` is nil

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
