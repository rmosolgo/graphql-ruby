# frozen_string_literal: true
module GraphQL
  # Error raised when the value provided for a field
  # can't be resolved to one of the possible types for the field.
  class UnresolvedTypeError < GraphQL::RuntimeTypeError
    # @return [Object] The runtime value which couldn't be successfully resolved with `resolve_type`
    attr_reader :value

    # @return [GraphQL::Field] The field whose value couldn't be resolved (`field.type` is type which couldn't be resolved)
    attr_reader :field

    # @return [GraphQL::BaseType] The owner of `field`
    attr_reader :parent_type

    # @return [Object] The return of {Schema#resolve_type} for `value`
    attr_reader :resolved_type

    # @return [Array<GraphQL::BaseType>] The allowed options for resolving `value` to `field.type`
    attr_reader :possible_types

    def initialize(value, field, parent_type, resolved_type, possible_types)
      @value = value
      @field = field
      @parent_type = parent_type
      @resolved_type = resolved_type
      @possible_types = possible_types
      abstract_type = field.type.unwrap
      message = "The value from \"#{field.graphql_name}\" on \"#{parent_type.graphql_name}\" could not be resolved to \"#{abstract_type.to_type_signature}\". " \
        "(Received: `#{resolved_type.name ? resolved_type.inspect : resolved_type.graphql_name}`, Expected: [#{possible_types.map(&:graphql_name).join(", ")}]) " \
        "Make sure you have defined a `resolve_type` method on your schema and that value `#{value.inspect}` " \
        "gets resolved to a valid type. You may need to add your type to `orphan_types` if it implements an " \
        "interface but isn't a return type of any other field."

      if abstract_type.kind.interface? && (multiplex = Fiber[:__graphql_current_multiplex])
        types = multiplex.queries.first.types
        if types.is_a?(Schema::Visibility::Profile)
          visibility = types.instance_variable_get(:@visibility)
          cached_vis = types.instance_variable_get(:@cached_visible)
          message << "\n\n`#{abstract_type.graphql_name}.orphan_types`: #{abstract_type.orphan_types}"
          impls = visibility.all_interface_type_memberships[abstract_type]
          message << "\n`Schema.visibility.all_interface_type_memberships[#{abstract_type.graphql_name}]` (#{impls.size}):"
          impls.each do |(impl_type, memberships)|
            message << "\n    - `#{impl_type.graphql_name}` | Object? #{impl_type.kind.object?} | referenced? #{types.send(:referenced?, impl_type)} | visible? #{cached_vis[impl_type]} | membership_visible? #{memberships.map { |itm| cached_vis[itm]}}"
          end
        end
      end
      super(message)
    end
  end
end
