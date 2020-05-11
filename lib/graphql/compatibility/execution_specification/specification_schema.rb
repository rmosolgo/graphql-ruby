# frozen_string_literal: true
module GraphQL
  module Compatibility
    module ExecutionSpecification
      module SpecificationSchema
        BOGUS_NODE = OpenStruct.new({ bogus: true })

        DATA = {
          "1001" => OpenStruct.new({
            name: "Fannie Lou Hamer",
            birthdate: Time.new(1917, 10, 6),
            organization_ids: [],
          }),
          "1002" => OpenStruct.new({
            name: "John Lewis",
            birthdate: Time.new(1940, 2, 21),
            organization_ids: ["2001"],
          }),
          "1003" => OpenStruct.new({
            name: "Diane Nash",
            birthdate: Time.new(1938, 5, 15),
            organization_ids: ["2001", "2002"],
          }),
          "1004" => OpenStruct.new({
            name: "Ralph Abernathy",
            birthdate: Time.new(1926, 3, 11),
            organization_ids: ["2002"],
          }),
          "2001" => OpenStruct.new({
            name: "SNCC",
            leader_id: nil, # fail on purpose
          }),
          "2002" => OpenStruct.new({
            name: "SCLC",
            leader_id: "1004",
          }),
          "2003" => BOGUS_NODE,
        }

        # A list object must implement #each
        class CustomCollection
          def initialize(storage)
            @storage = storage
          end

          def each(&block)
            @storage.each(&block)
          end
        end

        module TestMiddleware
          def self.call(parent_type, parent_object, field_definition, field_args, query_context, &next_middleware)
            query_context[:middleware_log] && query_context[:middleware_log] << field_definition.name
            next_middleware.call
          end
        end

        def self.build(execution_strategy)
          organization_type = nil

          timestamp_type = GraphQL::ScalarType.define do
            name "Timestamp"
            coerce_input ->(value, _ctx) { Time.at(value.to_i) }
            coerce_result ->(value, _ctx) { value.to_i }
          end

          named_entity_interface_type = GraphQL::InterfaceType.define do
            name "NamedEntity"
            field :name, !types.String
          end

          person_type = GraphQL::ObjectType.define do
            name "Person"
            interfaces [named_entity_interface_type]
            field :name, !types.String
            field :birthdate, timestamp_type
            field :age, types.Int do
              argument :on, !timestamp_type
              resolve ->(obj, args, ctx) {
                if obj.birthdate.nil?
                  nil
                else
                  age_on = args[:on]
                  age_years = age_on.year - obj.birthdate.year
                  this_year_birthday = Time.new(age_on.year, obj.birthdate.month, obj.birthdate.day)
                  if this_year_birthday > age_on
                    age_years -= 1
                  end
                end
                age_years
              }
            end
            field :organizations, types[organization_type] do
              resolve ->(obj, args, ctx) {
                CustomCollection.new(obj.organization_ids.map { |id| DATA[id] })
              }
            end
            field :first_organization, !organization_type do
              resolve ->(obj, args, ctx) {
                DATA[obj.organization_ids.first]
              }
            end
          end

          organization_type = GraphQL::ObjectType.define do
            name "Organization"
            interfaces [named_entity_interface_type]
            field :name, !types.String
            field :leader, !person_type do
              resolve ->(obj, args, ctx) {
                DATA[obj.leader_id] || (ctx[:return_error] ? ExecutionError.new("Error on Nullable") : nil)
              }
            end
            field :returnedError, types.String do
              resolve ->(o, a, c) {
                GraphQL::ExecutionError.new("This error was returned")
              }
            end
            field :raisedError, types.String do
              resolve ->(o, a, c) {
                raise GraphQL::ExecutionError.new("This error was raised")
              }
            end

            field :nodePresence, !types[!types.Boolean] do
              resolve ->(o, a, ctx) {
                [
                  ctx.irep_node.is_a?(GraphQL::InternalRepresentation::Node),
                  ctx.ast_node.is_a?(GraphQL::Language::Nodes::AbstractNode),
                  false, # just testing
                ]
              }
            end
          end

          node_union_type = GraphQL::UnionType.define do
            name "Node"
            possible_types [person_type, organization_type]
          end

          query_type = GraphQL::ObjectType.define do
            name "Query"
            field :node, node_union_type do
              argument :id, !types.ID
              resolve ->(obj, args, ctx) {
                obj[args[:id]]
              }
            end

            field :requiredNode, node_union_type.to_non_null_type do
              argument :id, !types.ID
              resolve ->(obj, args, ctx) {
                obj[args[:id]]
              }
            end

            field :organization, !organization_type do
              argument :id, !types.ID
              resolve ->(obj, args, ctx) {
                if args[:id].start_with?("2")
                  obj[args[:id]]
                else
                  # test context.skip
                  ctx.skip
                end
              }
            end

            field :organizations, types[organization_type] do
              resolve ->(obj, args, ctx) {
                [obj["2001"], obj["2002"]]
              }
            end
          end

          GraphQL::Schema.define do
            query_execution_strategy execution_strategy
            query query_type

            resolve_type ->(type, obj, ctx) {
              if obj.respond_to?(:birthdate)
                person_type
              elsif obj.respond_to?(:leader_id)
                organization_type
              else
                nil
              end
            }

            type_error ->(err, ctx) {
              ctx[:type_errors] && (ctx[:type_errors] << err.value)
              ctx[:gobble] || GraphQL::Schema::DefaultTypeError.call(err, ctx)
            }
            middleware(TestMiddleware)
          end
        end
      end
    end
  end
end
