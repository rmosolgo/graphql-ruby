# frozen_string_literal: true
require "graphql/relay/mutation/instrumentation"
require "graphql/relay/mutation/resolve"
require "graphql/relay/mutation/result"

module GraphQL
  module Relay
    # Define a Relay mutation:
    #   - give it a name (used for derived inputs & outputs)
    #   - declare its inputs
    #   - declare its outputs
    #   - declare the mutation procedure
    #
    # `resolve` should return a hash with a key for each of the `return_field`s
    #
    # Inputs may also contain a `clientMutationId`
    #
    # @example Updating the name of an item
    #   UpdateNameMutation = GraphQL::Relay::Mutation.define do
    #     name "UpdateName"
    #
    #     input_field :name, !types.String
    #     input_field :itemId, !types.ID
    #
    #     return_field :item, ItemType
    #
    #     resolve ->(inputs, ctx) {
    #       item = Item.find_by_id(inputs[:id])
    #       item.update(name: inputs[:name])
    #       {item: item}
    #     }
    #   end
    #
    #   MutationType = GraphQL::ObjectType.define do
    #     # The mutation object exposes a field:
    #     field :updateName, field: UpdateNameMutation.field
    #   end
    #
    #   # Then query it:
    #   query_string = %|
    #     mutation updateName {
    #       updateName(input: {itemId: 1, name: "new name", clientMutationId: "1234"}) {
    #         item { name }
    #         clientMutationId
    #     }|
    #
    #    GraphQL::Query.new(MySchema, query_string).result
    #    # {"data" => {
    #    #   "updateName" => {
    #    #     "item" => { "name" => "new name"},
    #    #     "clientMutationId" => "1234"
    #    #   }
    #    # }}
    #
    # @example Using a GraphQL::Function
    #   class UpdateAttributes < GraphQL::Function
    #     attr_reader :model, :return_as, :arguments
    #
    #     def initialize(model:, return_as:, attributes:)
    #       @model = model
    #       @arguments = {}
    #       attributes.each do |name, type|
    #         arg_name = name.to_s
    #         @arguments[arg_name] = GraphQL::Argument.define(name: arg_name, type: type)
    #       end
    #       @arguments["id"] = GraphQL::Argument.define(name: "id", type: !GraphQL::ID_TYPE)
    #       @return_as = return_as
    #       @attributes = attributes
    #     end
    #
    #     def type
    #       fn = self
    #       GraphQL::ObjectType.define do
    #         name "Update#{fn.model.name}AttributesResponse"
    #         field :clientMutationId, types.ID
    #         field fn.return_as.keys[0], fn.return_as.values[0]
    #       end
    #     end
    #
    #     def call(obj, args, ctx)
    #       record = @model.find(args[:inputs][:id])
    #       new_values = {}
    #       @attributes.each { |a| new_values[a] = args[a] }
    #       record.update(new_values)
    #       { @return_as => record }
    #     end
    #   end
    #
    #   UpdateNameMutation = GraphQL::Relay::Mutation.define do
    #     name "UpdateName"
    #     function UpdateAttributes.new(model: Item, return_as: { item: ItemType }, attributes: {name: !types.String})
    #   end

    class Mutation
      include GraphQL::Define::InstanceDefinable
      accepts_definitions(
        :name, :description, :resolve,
        :return_type,
        :return_interfaces,
        input_field: GraphQL::Define::AssignArgument,
        return_field: GraphQL::Define::AssignObjectField,
        function: GraphQL::Define::AssignMutationFunction,
      )
      attr_accessor :name, :description, :fields, :arguments
      attr_writer :return_type, :return_interfaces

      ensure_defined(
        :input_fields, :return_fields, :name, :description,
        :fields, :arguments, :return_type,
        :return_interfaces, :resolve=,
        :field, :result_class, :input_type
      )
      # For backwards compat, but do we need this separate API?
      alias :return_fields :fields
      alias :input_fields :arguments

      def initialize
        @fields = {}
        @arguments = {}
        @has_generated_return_type = false
      end

      def has_generated_return_type?
        # Trigger the generation of the return type, if it is dynamically generated:
        return_type
        @has_generated_return_type
      end

      def resolve=(new_resolve_proc)
        @resolve_proc = new_resolve_proc
      end

      def field
        @field ||= begin
          relay_mutation = self
          field_resolve_proc = @resolve_proc
          GraphQL::Field.define do
            type(relay_mutation.return_type)
            description(relay_mutation.description)
            argument :input, !relay_mutation.input_type
            resolve(field_resolve_proc)
            mutation(relay_mutation)
          end
        end
      end

      def return_interfaces
        @return_interfaces ||= []
      end

      def return_type
        @return_type ||= begin
          @has_generated_return_type = true
          relay_mutation = self
          GraphQL::ObjectType.define do
            name("#{relay_mutation.name}Payload")
            description("Autogenerated return type of #{relay_mutation.name}")
            field :clientMutationId, types.String, "A unique identifier for the client performing the mutation.", property: :client_mutation_id
            interfaces relay_mutation.return_interfaces
            relay_mutation.return_fields.each do |name, field_obj|
              field name, field: field_obj
            end
            mutation(relay_mutation)
          end
        end
      end

      def input_type
        @input_type ||= begin
          relay_mutation = self
          input_object_type = GraphQL::InputObjectType.define do
            name("#{relay_mutation.name}Input")
            description("Autogenerated input type of #{relay_mutation.name}")
            input_field :clientMutationId, types.String, "A unique identifier for the client performing the mutation."
            mutation(relay_mutation)
          end
          input_fields.each do |name, arg|
            input_object_type.arguments[name] = arg
          end

          input_object_type
        end
      end

      def result_class
        @result_class ||= Result.define_subclass(self)
      end
    end
  end
end
