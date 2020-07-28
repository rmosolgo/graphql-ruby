# graphql-pro

### Breaking Changes

### Deprecations

### New Features

### Bug Fix

## 1.15.4 (28 July 2020)

### New Features

- Pundit: add `pundit_policy_class_for(object, context)` and `pundit_role_for(object, context)` for custom runtime lookups

## 1.15.3 (17 July 2020)

### Bug Fix

- Subscriptions: don't send empty updates when subscriptions return `:no_update`

## 1.15.2 (16 July 2020)

### New Features

- OperationStore: improve handling of archived operations in index views

## 1.15.1 (16 July 2020)

(Oops, bad release!)

## 1.15.0 (15 July 2020)

- OperationStore: Store & display `last_used_at` for operation store clients and operations. To upgrade, add the column to your ActiveRecord table:

  ```ruby
  add_column :graphql_client_operations, :last_used_at, :datetime
  ```

  (It works out-of-the-box with the Redis backend.)

  You can opt out of this feature by adding `use GraphQL::Pro::OperationStore, ... default_touch_last_used_at: false` to your schema setup.

- OperationStore: Add archive/unarchive workflow for operations. To upgrade, add the column to your table:

  ```ruby
  add_column :graphql_client_operations, :is_archived, :boolean, index: true
  ```

  (It works out-of-the-box with the Redis backend.)

- OperationStore: Fix indexing of enum values

## 1.14.1 (29 June 2020)

- CanCan: Accept `can_can_attribute:` configuration, which is passed as the third input to `.can?(...)`

## 1.14.0 (13 June 2020)

### New Features

- Add PubnubSubscriptions
- Update subscription implementations to support `broadcast: true` when available

### Bug Fix

- More Ruby 2.7 warning fixes

## 1.13.6 (8 June 2020)

### Bug Fix

- Return the proper `pageInfo` values when it's requested before `edges` or `nodes` (#2972)

## 1.13.5 (11 May 2020)

### Bug Fix

- Fix some warnings on Ruby 2.7

## 1.13.4 (17 Apr 2020)

### Bug Fix

- StableRelationConnection: properly return `hasNextPage: true` when `before` and `max_page_size` are used.

## 1.13.3 (2 Apr 2020)

### New Features

- `GraphQL::Pro::OperationStore::Migration` can be used to copy persisted operations from one backend to another (eg, ActiveRecord to Redis). See the source file, `lib/graphql/pro/operation_store/migration.rb` for docs.

## 1.13.2 (28 Mar 2020)

### Deprecations

- `GraphQL::Pro::Subscriptions` is deprecated; use `GraphQL::Pro::PusherSubscriptions` instead which works the same, but better (see below). This new name avoids confusion with the later-added `AblySubscriptions`.

### New Features

- `GraphQL::Pro::PusherSubscriptions` replaces `GraphQL::Pro::Subscriptions` and adds orphaned record cleanup. (No more dangling records in Redis.)

## 1.13.1 (12 Mar 2020)

- Use `nonce: true` when working with cursors in new stable connections

## 1.13.0 (10 Feb 2020)

### New Features

- OperationStore supports a `redis:` backend
- OperationStore supports an arbitrary `backend_class:` for persistence operations

### Bug Fix

- Use a loop when clearing Redis subscription state to avoid large stack traces #2701
- Handle empty subscription keys when publishing updates #2061

## 1.12.2 (22 Jan 2020)

### Bug Fix

- Improve backwards compat with OperationStore (Improve adding `.tracer`, use `.graphql_name` when indexing)

## 1.12.1 (20 Jan 2020)

### Bug Fix

- Fix OperationStore on class-based schemas with query instrumenters that use the query string

## 1.12.0 (20 Jan 2020)

### Deprecations

- `GraphQL::Pro::Monitoring` is deprecated; see Tracing for a replacement: https://graphql-ruby.org/queries/tracing.html
- `GraphQL::Pro::Repository` is deprecated; see OperationStore for a replacement: https://graphql-ruby.org/operation_store/overview.html

### New Features

- New stable connection support based on GraphQL-Ruby 1.10's new pagination implementation. New classes provide better handling of `NULL` values in order-by columns and they can be applied on a field-by-field basis(`GraphQL::Pro::SqliteStableRelationConnection`, `GraphQL::Pro::MySQLStableRelationConnection`, `GraphQL::Pro::PostgresStableRelationConnection`).

### Bug Fix

- Add the Access query analyzer to class-based schemas

## 1.11.0 (10 Oct 2019)

### New Features

- Forwards-compatibility for graphql 1.10.0
- Support 1.10.0.pre1's input object argument `loads:` authorization

## 1.10.8 (8 Oct 2019)

### Bug Fix

- Continue authorizing input object arguments
- Use millisecond-aware string format for datetimes in cursors

## 1.10.7 (22 Jul 2019)

### Bug Fix

- Support multiple subscriptions in one document

## 1.10.6 (27 Jun 2019)

### New Features

- Support custom `#can_can_ability` methods on query context for CanCanIntegration
- Support custom `#pundit_user` method on query context for PunditIntegration

### Bug Fix

- Fix off-by-one error when paginating backwards from the last item in a stable relation connection

## 1.10.5 (11 May 2019)

### New Features

- Include expected HMAC digest in OperationStore debug output

## 1.10.4 (26 Mar 2019)

### Bug Fix

- Include content-length and content-type headers in OperationStore JSON responses

## 1.10.3 (13 Mar 2019)

### Bug Fix

- Support stable connections ordered by Arel SQL literals

## 1.10.2 (11 Mar 2019)

### Bug Fix

- Support stable connections on realized views (which don't have primary keys)

## 1.10.1 (8 Mar 2019)

### Bug Fix

- Pundit integration: support `pundit_policy_class` String names when scoping connections

## 1.10.0 (5 Mar 2019)

### New Features

- Add `GraphQL::Pro::Defer`, implementing `@defer` for streaming responses

## 1.9.13 (4 Mar 2019)

### Bug Fix

- Pundit integration: correctly authorize fields when Query root is nil

## 1.9.12 (22 Feb 2019)

### Bug Fix

- Pundit integration: use overriden `pundit_policy_class` for scoping and mutation authorization

## 1.9.11 (20 Feb 2019)

### Bug Fix

- Pundit integration: Fields use the owner's configured `pundit_policy_class` if there is one
- Pundit integration: avoid conflicts with `#initialize` for schema classes that don't need it

## 1.9.10 (19 Feb 2019)

### Bug Fix

- Support inheritance with `pundit_policy_class(...)`

## 1.9.9 (13 Feb 2019)

### New Features

- Support `pundit_policy_class(...)` and `pundit_policy_class:` to manually specify a class or class name.

## 1.9.8 (30 Jan 2019)

### New Features

- Inject `context` into policy lookup hooks instead of just the user

## 1.9.7 (30 Jan 2019)

### New Features

- Extract `pundit_policy` and `scope_by_pundit_policy` hooks for user override

## 1.9.6 (18 Jan 2019)

### Bug Fix

- Properly render subscription context in dashboard

## 1.9.5 (14 Jan 2019)

## Bug Fix

- Don't pass arrays to Pundit scopes (fixes https://github.com/rmosolgo/graphql-ruby/issues/2008)

## 1.9.4 (11 Jan 2019)

## Bug Fix

- Prepare for future compat with graphql-ruby 1.9

## 1.9.3 (3 Dec 2018)

### Bug Fix

- Include table name when adding a default order-by-id to ActiveRecord Relations
- Raise if a required cursor attribute is missing
- Improve `rake routes` output for operation store endpoint
- Support already-parsed queries in subscription RedisStorage

## 1.9.2 (2 Nov 2018)

### Bug Fix

- Derp, remove the dummy app's `.log` files from the gem bundle
- Fix ordering bug when a SQL function call doesn't have an explicit order

## 1.9.1 (1 Nov 2018)

### Bug Fix

- Fix Pusher reference in AblySubscriptions

## 1.9.0 (27 Oct 2018)

### New Features

- Add `GraphQL::Pro::AblySubscriptions` for GraphQL subscriptions over Ably.io transport

## 1.8.2 (22 Oct 2018)

### Bug Fix

- Support `NULLS LAST` in stable cursors

## 1.8.1 (16 Oct 2018)

### Bug Fix

- Improve operation store models to work when `config.active_record.primary_key_prefix_type` is set

## 1.8.0 (11 Oct 2018)

### New Features

- Support Rails 3.2 with OperationStore
- Use `.select` to filter items in CanCanIntegration

### Bug Fix

- Properly send an _ability_ and the configured `can_can_action` to `.accessible_by`
- Use a string (not integer) for `Content-Length` header in the dashboard

## 1.7.13 (2 Oct 2018)

### Breaking Change

- `PunditIntegration`: instead of raising `MutationAuthorizationFailed` when an argument fails authorization, it will send a `GraphQL::UnauthorizedError` to your `Schema.unauthorized_object` hook. (This is what all other authorization failures do.) To retain the previous behavior, in your base mutation, add:

  ```ruby
  def unauthorized_by_pundit(owner, value)
    # Raise a runtime error to halt query execution
    raise "#{value} failed #{owner}'s auth check"
  end
  ```

  Otherwise, customize the handling of this behavior with `Schema.unauthorized_object`.

### Bug Fix

- Auth: mutation arguments which have authorization constraints but _don't_ load an object from the database will have _mutation instance_ passed to the auth check, not the input value.

## 1.7.12 (29 Aug 2018)

### New Features

- Add `GraphQL::Pro::CanCanIntegration` which leverages GraphQL-Ruby's built-in auth

## 1.7.11 (21 Aug 2018)

### Bug Fix

- `PunditIntegration`: Don't try to authorize loaded objects when they're `nil`

## 1.7.10 (10 Aug 2018)

### New Features

- Update `PunditIntegration` for arguments, unions, interfaces and mutations

## 1.7.9 (9 Aug 2018)

### New Features

- Add a new `PunditIntegration` which leverages the built-in authorization methods

## 1.7.8 (10 July 2018)

### Bug Fix

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
