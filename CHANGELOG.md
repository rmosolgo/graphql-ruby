# graphql-relay

## 0.8.0 (20 Mar 2016)

### New Feature

- Accept configs for `to_global_id` and `from_global_id`
- Support `graphql` 0.12+

## 0.7.1 (29 Feb 2016)

### Bug Fix

- Limit the `count(*)` when testing next page with ActiveRecord #28

## 0.7.0 (20 Feb 2016)

### New Feature

- `max_page_size` option for connections
- Support ActiveSupport 5.0.0.beta2

## 0.6.2 (11 Feb 2016)

### Bug Fix

- Correctly cast values from connection cursors #21
- Use class _name_ instead of class _object_ when finding a connection implementation (to support Rails autoloading) #16

## 0.6.1 (14 Dec 2015)

### Bug Fix

- Stringify `id` when passed into `to_global_id`

## 0.6.0 (11 Dec 2015)

### Breaking Change

- `GlobalNodeIdentification#object_from_id(id, ctx)` now accepts context as the second argument #9

## 0.5.1 (11 Dec 2015)


### Feature

- Allow custom UUID join string #15

### Bug Fix

- Remove implicit ActiveSupport dependency #14
