# frozen_string_literal: true
# typed: true
module GraphQL
  # Error raised when a value can't be resolved to one of the possible types
  # for an abstract type.
  class UnresolvedTypeError < GraphQL::RuntimeTypeError
    # **Returns**
    #
    # - `Object` — The runtime value which couldn't be successfully resolved with `resolve_type`
    attr_reader :value

    # **Returns**
    #
    # - `GraphQL::Field, nil` — The field whose value couldn't be resolved, or `nil` for an abstract root
    attr_reader :field

    # **Returns**
    #
    # - `GraphQL::BaseType` — The owner of `field`, or the abstract type when `field` is `nil`
    attr_reader :parent_type

    # **Returns**
    #
    # - `Object` — The return of [Schema.resolve_type](rdoc-ref:GraphQL::Schema::resolve_type) for `value`
    attr_reader :resolved_type

    # **Returns**
    #
    # - `Array<GraphQL::BaseType>` — The allowed options for resolving `value`
    attr_reader :possible_types

    def initialize(value, field, parent_type, resolved_type, possible_types)
      @value = value
      @field = field
      @parent_type = parent_type
      @resolved_type = resolved_type
      @possible_types = possible_types
      message = if field
        "The value from \"#{field.graphql_name}\" on \"#{parent_type.graphql_name}\" could not be resolved to \"#{field.type.to_type_signature}\". "
      else
        "The value for \"#{parent_type.graphql_name}\" could not be resolved to one of its possible types. "
      end
      message += "(Received: `#{resolved_type.inspect}`, Expected: [#{possible_types.map(&:graphql_name).join(", ")}]) " \
        "Make sure you have defined a `resolve_type` proc on your schema and that value `#{value.inspect}` " \
        "gets resolved to a valid type. You may need to add your type to `orphan_types` if it implements an " \
        "interface but isn't a return type of any other field."
      super(message)
    end
  end
end
