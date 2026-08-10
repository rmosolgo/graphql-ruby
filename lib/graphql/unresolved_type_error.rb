# frozen_string_literal: true
module GraphQL
  # Error raised when the value provided for a field
  # can't be resolved to one of the possible types for the field.
  class UnresolvedTypeError < GraphQL::RuntimeTypeError
    # **Returns**
    #
    # - `Object` — The runtime value which couldn't be successfully resolved with `resolve_type`
    #
    # :call-seq:
    #   value -> Object
    attr_reader :value

    # **Returns**
    #
    # - `GraphQL::Field` — The field whose value couldn't be resolved (`field.type` is type which couldn't be resolved)
    #
    # :call-seq:
    #   field -> GraphQL::Field
    attr_reader :field

    # **Returns**
    #
    # - `GraphQL::BaseType` — The owner of `field`
    #
    # :call-seq:
    #   parent_type -> GraphQL::BaseType
    attr_reader :parent_type

    # **Returns**
    #
    # - `Object` — The return of [Schema.resolve_type](rdoc-ref:GraphQL::Schema::resolve_type) for `value`
    #
    # :call-seq:
    #   resolved_type -> Object
    attr_reader :resolved_type

    # **Returns**
    #
    # - `Array<GraphQL::BaseType>` — The allowed options for resolving `value` to `field.type`
    #
    # :call-seq:
    #   possible_types -> Array[GraphQL::BaseType]
    attr_reader :possible_types

    def initialize(value, field, parent_type, resolved_type, possible_types)
      @value = value
      @field = field
      @parent_type = parent_type
      @resolved_type = resolved_type
      @possible_types = possible_types
      message = "The value from \"#{field.graphql_name}\" on \"#{parent_type.graphql_name}\" could not be resolved to \"#{field.type.to_type_signature}\". " \
        "(Received: `#{resolved_type.inspect}`, Expected: [#{possible_types.map(&:graphql_name).join(", ")}]) " \
        "Make sure you have defined a `resolve_type` proc on your schema and that value `#{value.inspect}` " \
        "gets resolved to a valid type. You may need to add your type to `orphan_types` if it implements an " \
        "interface but isn't a return type of any other field."
      super(message)
    end
  end
end
