# frozen_string_literal: true
require 'graphql/generators/type_generator'

module GraphQL
  module Generators
    # Generate an object type by name,
    # with the specified fields.
    #
    # ```
    # rails g graphql:object PostType name:String!
    # ```
    #
    # Add the Node interface with `--node`.
    class ObjectGenerator < TypeGenerator
      desc "Create a GraphQL::ObjectType with the given name and fields"
      source_root File.expand_path('../templates', __FILE__)

      argument :fields,
        type: :array,
        default: [],
        banner: "name:type name:type ...",
        description: "Fields for this object (type may be expressed as Ruby or GraphQL)"

      class_option :node,
        type: :boolean,
        default: false,
        description: "Include the Relay Node interface"

      def create_type_file
        template "object.erb", "app/graphql/types/#{type_file_name}.rb"
      end
    end
  end
end
