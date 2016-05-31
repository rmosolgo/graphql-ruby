# graphql-relay

## 0.10.0 (31 May 2016)

### New Feature

- Support `graphql` 0.14.0 #47

## Bug Fix

- Use strings as argument names, not symbols #47

## 0.9.5

### New Feature

- Root `id` field may have a description #43

## 0.9.4 (29 Apr 2016)

### Bug Fix

- Fix Node interface to support GraphQL 0.13.0+

## 0.9.2 (29 Apr 2016)

### Bug Fix

- Fix Node interface when type_from_object returns nil

## 0.9.1 (6 Apr 2016)

### Bug Fix

- Respond to connection fields without any pagination arguments
- Limit by `max_page_size` even when no arguments are present

## 0.9.0 (30 Mar 2016)

### Breaking change

- Remove the `order` argument from connection fields. This isn't part of the spec and shouldn't have been there in the first place!

  You can implement this behavior with a custom argument, for example:

   ```ruby
   field :cities, CityType.connection_type do
     argument :order, types.String, default_value: "name"
     resolve -> (obj, args, ctx) {
       obj.order(args[:order])
     }
   end
   ```

### Bug Fix

- Include the MIT license in the project's source

## 0.8.1 (22 Mar 2016)

### Bug Fix

- Accept description for Mutations

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
