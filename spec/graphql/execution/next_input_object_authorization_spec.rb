# frozen_string_literal: true
require "spec_helper"

describe "Next Execution input object authorization" do
  class NextInputObjectAuthorizationSchema < GraphQL::Schema
    class MakeAdminArgument < GraphQL::Schema::Argument
      def authorized?(object, value, context)
        super && !value
      end
    end

    class PermissionsInput < GraphQL::Schema::InputObject
      argument_class MakeAdminArgument
      argument :make_admin, Boolean
    end

    class WrapperInput < GraphQL::Schema::InputObject
      argument :permissions, PermissionsInput, required: false
      argument :permission_sets, [PermissionsInput], required: false
      argument :child, self, required: false
    end

    class Query < GraphQL::Schema::Object
      field :value, String
    end

    class Mutation < GraphQL::Schema::Object
      field :change_permissions, Boolean, resolve_legacy_instance_method: true do
        argument :input, WrapperInput
      end

      def change_permissions(input:)
        context[:resolved] << input.to_h
        true
      end
    end

    query(Query)
    mutation(Mutation)
    use GraphQL::Execution::Next
  end

  [:execute_legacy, :execute_next].each do |engine|
    [true, false].each do |make_admin|
      it "#{make_admin ? 'rejects' : 'accepts'} nested arguments with #{engine}" do
        inputs = [
          ["{ permissions: { makeAdmin: #{make_admin} } }", { permissions: { makeAdmin: make_admin } }],
          ["{ permissionSets: [{ makeAdmin: false }, { makeAdmin: #{make_admin} }] }", { permissionSets: [{ makeAdmin: false }, { makeAdmin: make_admin }] }],
          ["{ child: { permissions: { makeAdmin: #{make_admin} } } }", { child: { permissions: { makeAdmin: make_admin } } }],
        ]
        inputs.each do |literal, input|
          [
            ["mutation { changePermissions(input: #{literal}) }", {}],
            ["mutation($input: WrapperInput!) { changePermissions(input: $input) }", { input: input }],
          ].each do |query, variables|
            context = { resolved: [] }
            result = NextInputObjectAuthorizationSchema.public_send(engine, query, variables: variables, context: context).to_h
            if make_admin
              assert_nil result.dig("data", "changePermissions")
            else
              assert_equal true, result.dig("data", "changePermissions")
            end
            assert_nil result["errors"]
            assert_equal make_admin ? 0 : 1, context[:resolved].size
          end
        end
      end
    end
  end
end
