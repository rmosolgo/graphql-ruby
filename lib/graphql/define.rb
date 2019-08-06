# frozen_string_literal: true
require "graphql/define/assign_argument"
require "graphql/define/assign_connection"
require "graphql/define/assign_enum_value"
require "graphql/define/assign_global_id_field"
require "graphql/define/assign_mutation_function"
require "graphql/define/assign_object_field"
require "graphql/define/defined_object_proxy"
require "graphql/define/instance_definable"
require "graphql/define/no_definition_error"
require "graphql/define/non_null_with_bang"
require "graphql/define/type_definer"

module GraphQL
  module Define
    # A helper for definitions that store their value in `#metadata`.
    #
    # @example Storing application classes with GraphQL types
    #   # Make a custom definition
    #   GraphQL::ObjectType.accepts_definitions(resolves_to_class_names: GraphQL::Define.assign_metadata_key(:resolves_to_class_names))
    #
    #   # After definition, read the key from metadata
    #   PostType.metadata[:resolves_to_class_names] # => [...]
    #
    # @param key [Object] the key to assign in metadata
    # @return [#call(defn, value)] an assignment for `.accepts_definitions` which writes `key` to `#metadata`
    def self.assign_metadata_key(key)
      GraphQL::Define::InstanceDefinable::AssignMetadataKey.new(key)
    end
  end
end
