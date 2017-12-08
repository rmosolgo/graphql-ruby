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
    new = %{field :name, String, method: :name, null: true}

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
        class UserType < Types::BaseObject
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
        class TeamType < Types::BaseObject
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
        class UserInterface < Types::BaseInterface
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
        class UserInterface < Types::BaseInterface
          graphql_name "User"
        end
      }
      assert_equal upgrade(old), new
    end
  end

  describe 'definition' do
    it 'upgrades the .define into class based definition' do
      old = %{UserType = GraphQL::ObjectType.define do}
      new = %{class UserType < Types::BaseObject}
      assert_equal upgrade(old), new

      old = %{UserInterface = GraphQL::InterfaceType.define do}
      new = %{class UserInterface < Types::BaseInterface}
      assert_equal upgrade(old), new

      old = %{UserUnion = GraphQL::UnionType.define do}
      new = %{class UserUnion < Types::BaseUnion}
      assert_equal upgrade(old), new

      old = %{UserEnum = GraphQL::EnumType.define do}
      new = %{class UserEnum < Types::BaseEnum}
      assert_equal upgrade(old), new
    end

    it 'upgrades including the module' do
      old = %{Module::UserType = GraphQL::ObjectType.define do}
      new = %{class Module::UserType < Types::BaseObject}
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
      new = %{field :name, Name.connection_type, "names", null: true, connection: true}
      assert_equal upgrade(old), new

      old = %{connection :name, !Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", null: false, connection: true}
      assert_equal upgrade(old), new

      old = %{field :names, types[types.String]}
      new = %{field :names, [String], null: true}
      assert_equal upgrade(old), new

      old = %{field :names, !types[types.String]}
      new = %{field :names, [String], null: false}
      assert_equal upgrade(old), new

      old = %{
        field :name, types.String do
        end
      }
      new = %{
        field :name, String, null: true do
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
        field :name, -> { String }, null: true do
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
        field :name, -> { String }, "newline description", null: true do
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
       field :name, String, field: SomeField, null: true do
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
        field :is_example_field, Boolean, null: true
          method: :example_field?
      }

      assert_equal upgrade(old), new
    end
  end

  describe 'multi-line connection with property/method' do
    it 'upgrades without breaking syntax' do
      old = %{
        connection :example_connection, -> { ExampleConnectionType },
          property: :example_connections
      }
      new = %{
        field :example_connection, -> { ExampleConnectionType }, null: true, connection: true
          method: :example_connections
      }

      assert_equal upgrade(old), new
    end
  end
end
