---
layout: guide
doc_stub: false
search: true
section: Fields
title: Validation
desc: Rails-like validations for arguments and fields
index: 3
---

Fields (and their arguments, and input object arguments) can be validated at runtime using built-in or custom validators.

Validations are configured in `field(...)` or `argument(...)` calls:

```ruby
argument :home_phone, String,
  description: "A US phone number",
  validates: { format: { with: /\d{3}-\d{3}-\d{4}/ } }
```

or:

```ruby
field :comments, [Comment],
  description: "Find comments by author ID or author name" do
  argument :author_id, ID, required: false
  argument :author_name, String, required: false
  # Either `authorId` or `authorName` must be provided by the client, but not both:
  validates required: { one_of: [:author_id, :author_name] }
end
```

Validations can be provided with a keyword (`validates: { ... }`) or with a method inside the configuration block (`validates ...`).

## Built-In Validations

All the validators below accept the following options:

- `allow_blank: true` will permit any input that responds to `.blank?` and returns true for it.
- `allow_null: true` will permit `null` (from JS) and/or `nil` (from Ruby) (bypassing the validation)
- `message: "..."` customizes the error message when the validation fails

For example:

```ruby
field :comments, [Comment],
  description: "Find comments by author ID or author name" do
  argument :author_id, ID, required: false
  argument :author_name, String, required: false
  # Include a message for the end user if the validation fails:
  validates required: {
    one_of: [:author_id, :author_name],
    message: "May use either author_id or author_name, but not both."
  }
end
```

See each validator's API docs for details:

- `length: { maximum: ..., minimum: ..., is: ..., within: ... }` {{ "Schema::Validator::LengthValidator" | api_doc }}
- `format: { with: /.../, without: /.../ }` {{ "Schema::Validator::FormatValidator" | api_doc }}
- `numericality: { greater_than:, greater_than_or_equal_to:, less_than:, less_than_or_equal_to:, other_than:, odd:, even: }` {{ "Schema::Validator::NumericalityValidator" | api_doc }}
- `inclusion: { in: [...] }` {{ "Schema::Validator::InclusionValidator" | api_doc }}
- `exclusion: { in: [...] }` {{ "Schema::Validator::ExclusionValidator" | api_doc }}
- `required: { one_of: [...] }` {{ "Schema::Validator::RequiredValidator" | api_doc }}


Some of the validators accept customizable messages for certain validation failures; see the API docs for examples.

## Custom Validators

You can write custom validators, too. A validator is a class that extends `GraphQL::Schema::Validator`. It should implement:

- `def initialize(..., **default_options)` to accept any validator-specific options and pass along the defaults to `super(**default_options)`
- `def validate(object, context, value)` which is called at runtime to validate `value`. It may return a String error message or an Array of Strings. GraphQL-Ruby will add those messages to the top-level `"errors"` array along with runtime context information.

Then, custom validators can be attached either:

- directly, passed to `validates`, like `validates: { MyCustomValidator => { some: :options }`
- by keyword, if the keyword is registered with `GraphQL::Schema::Validator.install(:custom, MyCustomValidator)`. (That would support `validates: { custom: { some: :options }})`.)

Validators are initialized when the schema is constructed (at application boot), and `validate(...)` is called while executing the query. There's one `Validator` instance for each configuration on each field, argument, or input object. (`Validator` instances aren't shared.)
