# frozen_string_literal: true

require "spec_helper"
require './lib/graphql/upgrader/member.rb'

describe GraphQL::Upgrader::Member do
  def assert_equal_ignore_spaces(a, b)
    a = a.split("\n").map{|line| line.strip}.select{|line| !line.empty?}.join("\n")
    b = b.split("\n").map{|line| line.strip}.select{|line| !line.empty?}.join("\n")
    assert_equal(a, b)
  end

  def upgrade(old)
    GraphQL::Upgrader::Member.new(old).upgrade
  end

  describe 'field arguments' do
    it 'upgrades' do
      old = %{argument :status, !TodoStatus, "Restrict items to this status"}
      new = %{argument :status, TodoStatus, "Restrict items to this status", required: true}

      assert_equal_ignore_spaces new, upgrade(old)
    end
  end

  it 'upgrades the property definition to method' do
    old = %{field :name, String, property: :name}
    new = %{field :name, String, null: true, method: :name}

    assert_equal_ignore_spaces new, upgrade(old)
  end

  describe 'name' do
    it 'removes the name field if it can be inferred from the class' do
      old = %{
        UserType = GraphQL::ObjectType.define do
          # here is the name:
          name "User"
        end
      }
      new = %{
        class UserType < Types::BaseObject
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)
    end

    it 'removes the name field if it can be inferred from the class and under a module' do
      old = %{
        Types::UserType = GraphQL::ObjectType.define do
          name "User"
        end
      }
      new = %{
        class Types::UserType < Types::BaseObject
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)
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
      assert_equal_ignore_spaces new, upgrade(old)

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
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        UserEnum = GraphQL::EnumType.define do
          name "User"
        end
      }
      new = %{
        class UserEnum < Types::BaseEnum
          graphql_name "User"
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)
    end
  end

  describe 'definition' do
    it 'upgrades the .define into class based definition' do
      old = %{UserType = GraphQL::ObjectType.define do; end}
      new = %{class UserType < Types::BaseObject; end}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{UserInterface = GraphQL::InterfaceType.define do; end}
      new = %{class UserInterface < Types::BaseInterface; end}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{UserUnion = GraphQL::UnionType.define do; end}
      new = %{class UserUnion < Types::BaseUnion; end}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{UserEnum = GraphQL::EnumType.define do; end}
      new = %{class UserEnum < Types::BaseEnum; end}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{UserInput = GraphQL::InputObjectType.define do; end}
      new = %{class UserInput < Types::BaseInputObject; end}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{UserScalar = GraphQL::ScalarType.define do; end}
      new = %{class UserScalar < Types::BaseScalar; end}
      assert_equal_ignore_spaces new, upgrade(old)
    end

    it 'upgrades including the module' do
      old = %{Module::UserType = GraphQL::ObjectType.define do; end}
      new = %{class Module::UserType < Types::BaseObject; end}
      assert_equal_ignore_spaces new, upgrade(old)
    end
  end

  describe 'fields' do
    it 'upgrades to the new definition' do
      old = %{field :name, !types.String}
      new = %{field :name, String, null: false}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{field :name, !types.String, "description", method: :name}
      new = %{field :name, String, "description", null: false, method: :name}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{field :name, -> { !types.String }}
      new = %{field :name, -> { String }, null: false}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{connection :name, Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", null: true, connection: true}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{connection :name, !Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", null: false, connection: true}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{field :names, types[types.String]}
      new = %{field :names, [String], null: true}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{field :names, !types[types.String]}
      new = %{field :names, [String], null: false}
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        field :name, types.String do
        end
      }
      new = %{
        field :name, String, null: true do
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        field :name, !types.String do
        end
      }
      new = %{
        field :name, String, null: false do
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        field :name, -> { !types.String } do
        end
      }
      new = %{
        field :name, -> { String }, null: false do
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        field :name do
          type -> { String }
        end
      }
      new = %{
        field :name, -> { String }, null: true do
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        field :name do
          type !String
        end
      }
      new = %{
        field :name, String, null: false do
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        field :name, -> { types.String },
          "newline description" do
        end
      }
      new = %{
        field :name, -> { String },
          "newline description", null: true do
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        field :name, -> { !types.String },
          "newline description" do
        end
      }
      new = %{
        field :name, -> { String },
          "newline description", null: false do
        end
      }
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
       field :name, String,
         field: SomeField do
       end
      }
      new = %{
       field :name, String, null: true,
        field: SomeField do
       end
      }
      assert_equal_ignore_spaces new, upgrade(old)

      old = %{
        Types::AuthorType = GraphQL::ObjectType.define do
          field :name, property: :name do
            type -> { types.String } # name's type is String
            description 'Name'
            argument :isIncludeLastName, !types.Boolean, 'Is include last name?'
            resolve ->(obj, args, ctx) {
              if args[:isIncludeLastName]
                obj.first_name + ' ' + obj.last_name.upcase
              else
                obj.first_name
              end
            }
          end
        end
      }
      new = %{
        class Types::AuthorType < Types::BaseObject
          field :name, -> { String }, 'Name', null: true, method: :name, resolve: ->(obj, args, ctx) {
              if args[:isIncludeLastName]
                obj.first_name + ' ' + obj.last_name.upcase
              else
                obj.first_name
              end
            } do
             # name's type is String
            argument :isIncludeLastName, Boolean, 'Is include last name?', required: true
          end
        end
      }
      # p new, upgrade(old)
      assert_equal_ignore_spaces new, upgrade(old)
    end
  end

  describe 'multi-line field with property/method' do
    it 'upgrades without breaking syntax' do
      old = %{
        field :is_example_field, types.Boolean,
          property: :example_field?
      }
      new = %{
        field :is_example_field, Boolean, null: true,
          method: :example_field?
      }

      assert_equal_ignore_spaces new, upgrade(old)
    end
  end

  describe 'multi-line connection with property/method' do
    it 'upgrades without breaking syntax' do
      old = %{
        connection :example_connection, -> { ExampleConnectionType },
          property: :example_connections
      }
      new = %{
        field :example_connection, -> { ExampleConnectionType }, null: true, connection: true,
          method: :example_connections
      }

      assert_equal_ignore_spaces new, upgrade(old)
    end
  end

  describe 'input_field' do
    it 'upgrades to argument' do
      old = %{input_field :id, !types.ID}
      new = %{argument :id, ID, required: true}
      assert_equal_ignore_spaces new, upgrade(old)
    end
  end

  describe 'implements' do
    it 'upgrades interfaces to implements' do
      old = %{
        interfaces [Types::SearchableType, Types::CommentableType]
        interfaces [Types::ShareableType]
      }
      new = %{
        implements Types::SearchableType
        implements Types::CommentableType
        implements Types::ShareableType
      }
      assert_equal_ignore_spaces new, upgrade(old)
    end
  end
end
