# frozen_string_literal: true
module Graphql
  module Generators
    module Relay
      def install_relay
        # Add Node, `node(id:)`, and `nodes(ids:)`
        template("node_type.erb", "#{options[:directory]}/types/node_type.rb")
        in_root do
          fields = "    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`\n    include GraphQL::Types::Relay::HasNodeField\n    include GraphQL::Types::Relay::HasNodesField\n\n"
          inject_into_file "#{options[:directory]}/types/query_type.rb", fields, after: /class .*QueryType\s*<\s*[^\s]+?\n/m, force: false
        end

        # Add connections and edges
        template("base_connection.erb", "#{options[:directory]}/types/base_connection.rb")
        template("base_edge.erb", "#{options[:directory]}/types/base_edge.rb")
        connectionable_type_files = {
          "#{options[:directory]}/types/base_object.rb" => /class .*BaseObject\s*<\s*[^\s]+?\n/m,
          "#{options[:directory]}/types/base_union.rb" =>  /class .*BaseUnion\s*<\s*[^\s]+?\n/m,
          "#{options[:directory]}/types/base_interface.rb" => /include GraphQL::Schema::Interface\n/m,
        }
        in_root do
          connectionable_type_files.each do |type_class_file, sentinel|
            inject_into_file type_class_file, "    connection_type_class(Types::BaseConnection)\n", after: sentinel, force: false
            inject_into_file type_class_file, "    edge_type_class(Types::BaseEdge)\n", after: sentinel, force: false
          end
        end

        # Add object ID hooks & connection plugin
        schema_code = <<-RUBY

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, type_definition, query_ctx)
    # Here's a simple implementation which:
    # - joins the type name & object.id
    # - encodes it with base64:
    # GraphQL::Schema::UniqueWithinType.encode(type_definition.name, object.id)
  end

  # Given a string UUID, find the object
  def self.object_from_id(id, query_ctx)
    # For example, to decode the UUIDs generated above:
    # type_name, item_id = GraphQL::Schema::UniqueWithinType.decode(id)
    #
    # Then, based on `type_name` and `id`
    # find an object in your application
    # ...
  end
RUBY
        inject_into_file schema_file_path, schema_code, before: /^end\n/m, force: false
      end
    end
  end
end
