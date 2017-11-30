# frozen_string_literal: true

require "spec_helper"
require './lib/graphql/upgrader/member.rb'

describe GraphQL::Upgrader::Member do
  def upgrade(old)
    GraphQL::Upgrader::Member.new(old).upgrade
  end

  describe 'field arguments' do
    it 'upgrades' do
      old = %{argument :status, !TodoStatus, "Restrict items to this status"}
      new = %{argument :status, TodoStatus, "Restrict items to this status", null: false}

      assert_equal upgrade(old), new
    end
  end

  it 'upgrades the property definition to method' do
    old = %{field :name, String, property: :name}
    new = %{field :name, String, method: :name, null: false}

    assert_equal upgrade(old), new
  end

  describe 'name' do
    it 'removes the name field if it can be inferred from the class' do
      old = %{
        UserType = GraphQL::ObjectType.define do
          name "User"
        end
      }
      new = %{
        class UserType < BaseObject
        end
      }
      assert_equal upgrade(old), new
    end

    it 'upgrades the name into graphql_name if it can\'t be inferred from the class' do
      old = %{
        TeamType = GraphQL::ObjectType.define do
          name "User"
        end
      }
      new = %{
        class TeamType < BaseObject
          graphql_name "User"
        end
      }
      assert_equal upgrade(old), new

      old = %{
        UserInterface = GraphQL::InterfaceType.define do
          name "User"
        end
      }
      new = %{
        class UserInterface < BaseInterface
          graphql_name "User"
        end
      }
      assert_equal upgrade(old), new

      old = %{
        UserInterface = GraphQL::InterfaceType.define do
          name "User"
        end
      }
      new = %{
        class UserInterface < BaseInterface
          graphql_name "User"
        end
      }
      assert_equal upgrade(old), new
    end
  end

  describe 'definition' do
    it 'upgrades the .define into class based definition' do
      old = %{UserType = GraphQL::ObjectType.define do}
      new = %{class UserType < BaseObject}
      assert_equal upgrade(old), new

      old = %{UserInterface = GraphQL::InterfaceType.define do}
      new = %{class UserInterface < BaseInterface}
      assert_equal upgrade(old), new

      old = %{UserUnion = GraphQL::UnionType.define do}
      new = %{class UserUnion < BaseUnion}
      assert_equal upgrade(old), new

      old = %{UserEnum = GraphQL::EnumType.define do}
      new = %{class UserEnum < BaseEnum}
      assert_equal upgrade(old), new
    end

    it 'upgrades including the module' do
      old = %{Module::UserType = GraphQL::ObjectType.define do}
      new = %{class Module::UserType < BaseObject}
      assert_equal upgrade(old), new
    end
  end

  describe 'fields' do
    it 'upgrades to the new definition' do
      old = %{field :name, !types.String}
      new = %{field :name, String, null: false}
      assert_equal upgrade(old), new

      old = %{field :name, !types.String, "description", method: :name}
      new = %{field :name, String, "description", method: :name, null: false}
      assert_equal upgrade(old), new

      old = %{field :name, -> { !types.String }}
      new = %{field :name, -> { String }, null: false}
      assert_equal upgrade(old), new

      old = %{connection :name, Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", null: false, connection: true}
      assert_equal upgrade(old), new

      old = %{connection :name, !Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", null: false, connection: true}
      assert_equal upgrade(old), new

      old = %{field :names, types[types.String]}
      new = %{field :names, [String], null: false}
      assert_equal upgrade(old), new

      old = %{field :names, !types[types.String]}
      new = %{field :names, [String], null: false}
      assert_equal upgrade(old), new

      old = %{
        field :name, types.String do
        end
      }
      new = %{
        field :name, String, null: false do
        end
      }
      assert_equal upgrade(old), new

      old = %{
        field :name, !types.String do
        end
      }
      new = %{
        field :name, String, null: false do
        end
      }
      assert_equal upgrade(old), new

      old = %{
        field :name, -> { !types.String } do
        end
      }
      new = %{
        field :name, -> { String }, null: false do
        end
      }
      assert_equal upgrade(old), new

      old = %{
        field :name do
          type -> { String }
        end
      }
      new = %{
        field :name, -> { String }, null: false do
        end
      }
      assert_equal upgrade(old), new

      old = %{
        field :name do
          type !String
        end
      }
      new = %{
        field :name, String, null: false do
        end
      }
      assert_equal upgrade(old), new

      old = %{
        field :name, -> { types.String },
          "newline description" do
        end
      }
      new = %{
        field :name, -> { String }, "newline description", null: false do
        end
      }
      assert_equal upgrade(old), new

      old = %{
        field :name, -> { !types.String },
          "newline description" do
        end
      }
      new = %{
        field :name, -> { String }, "newline description", null: false do
        end
      }
      assert_equal upgrade(old), new

      old = %{
       field :name, String,
         field: SomeField do
       end
      }
      new = %{
       field :name, String, field: SomeField, null: false do
       end
      }
      assert_equal upgrade(old), new
    end
  end

  describe 'complicated inline definition' do
    it 'upgrades without breaking syntax' do
      old = %{
        connection :example_connection, -> { ExampleConnectionType } do
          argument :order_by, (GraphQL::InputObjectType.define do
            name 'ExampleConnectionOrder'
            argument :direction, -> { !ExampleConnectionDirectionEnum }
            argument :field, -> { !ExampleConnectionFieldEnum }
          end), default_value: { direction: 'DESC', field: 'created_at' }

          resolve ->(o, a, c) do
            Resolvers::ExampleConnectionResolver.call o.example_connections, order_by: args.order_by
          end
        end
      }
      new = %{
        field :example_connection, -> { ExampleConnectionType }, null: true, connection: true do
          argument :order_by, (GraphQL::InputObjectType.define null: false do
            name 'ExampleConnectionOrder'
            argument :direction, -> { ExampleConnectionDirectionEnum }, null: false
            argument :field, -> { ExampleConnectionFieldEnum }, null: false
          end), default_value: { direction: 'DESC', field: 'created_at' }

          resolve ->(o, a, c) do
            Resolvers::ExampleConnectionResolver.call o.example_connections, order_by: args.order_by
          end
        end
      }
      assert_equal upgrade(old), new
    end
  end

  describe 'multi-line field with property/method' do
    it 'upgrades without breaking syntax' do
      old = %{
        field :is_example_field, types.Boolean,
          property: :example_field?
      }
      new = %{
        field :is_example_field, Boolean, null: false
          method: :example_field?
      }
      assert_equal upgrade(old), new
    end
  end
end
