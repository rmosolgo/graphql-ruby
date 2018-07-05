---
layout: guide
doc_stub: false
search: true
section: Mutations
title: Mutation authorization
desc: Checking permissions for mutations
index: 3
---

Before running a mutation, you probably want to do a few things:

- Make sure the current user has permission to try this mutation
- Load some objects from the database, using some `ID` inputs
- Check if the user has permission to modify those loaded objects

This guide describes how to accomplish that workflow with GraphQL-Ruby.

## Checking the user permissions

Before loading any data from the database, you might want to see if the user has a certain permission level. For example, maybe only `.admin?` users can run `Mutation.promoteEmployee`.

This check can be implemented using the `#before_prepare` method in a mutation:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  def before_prepare(**args)
    if !context[:current_user].admin?
      raise GraphQL::ExecutionError, "Only admins can run this mutation"
    end
  end

  # ...
end
```

Now, when any non-`admin` user tries to run the mutation, it won't run. Instead, they'll get an error in the response.

## Loading and authorizing objects

Often, mutations take `ID`s as input and use them to load records from the database. GraphQL-Ruby can load IDs for you when you provide a `loads:` option.

In short, here's an example:


```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  # `employeeId` is an ID, Types::Employee is an _Object_ type
  argument :employee_id, ID, required: true, loads: Types::Employee

  # Behind the scenes, `:employee_id` is used to fetch an object from the database,
  # then the object is authorized with `Employee.authorized?`, then
  # if all is well, the object is injected here:
  def resolve(employee:)
    employee.promote!
  end
end
```

It works like this: if you pass a `loads:` option, it will:

- Automatically remove `_id` from the name and pass that name for the `as:` option
- Add a prepare hook to fetch an object with the given `ID` (using {{ "Schema.object_from_id" | api_doc }})
- Check that the fetched object's type matches the `loads:` type (using {{ "Schema.resolve_type" | api_doc }})
- Run the fetched object through its type's `.authorized?` hook (see {% internal_link "Authorization", "/authorization/authorization" %})
- Inject it into `#resolve` using the object-style name (`employee:`)

In this case, if the argument value is provided by `object_from_id` doesn't return a value, the mutation will fail with an error.

If you don't want this behavior, don't use it. Instead, create arguments with type `ID` and use them your own way, for example:

```ruby
# No special loading behavior:
argument :employee_id, ID, required: true
```

## Can _this user_ modify _this thing_?

Sometimes you need to authorize a specific user-object-action combination. For example, `.admin?` users can't promote _all_ employees! They can only promote employees which they manage.

You can add this check by implementing a `#validate_#{arg_name}` method, for example:

```ruby
def validate_employee(employee)
  if !context[:current_user].manager_of?(employee)
    raise GraphQL::ExecutionError, "You can only promote your _own_ employees"
  end
end
```

If this method raises an error, the mutation will be halted.

## Finally, doing the work

Now that the user has been authorized in general, data has been loaded, and objects have been validated in particular, you can modify the database using `#resolve`:

```ruby
def resolve(employee:)
  if employee.promote
    {
      employee: employee,
      errors: [],
    }
  else
    # See "Mutation Errors" for more:
    {
      errors: employee.errors.full_messages
    }
  end
end
```
