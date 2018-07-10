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
      new = %{argument :status, TodoStatus, "Restrict items to this status", required: true}

      assert_equal new, upgrade(old)
    end
  end

  describe "property / method upgrade" do
    it 'upgrades the property definition to method' do
      old = %{field :name, String, property: :full_name}
      new = %{field :name, String, method: :full_name, null: true}

      assert_equal new, upgrade(old)
    end

    it 'upgrades the property definition in a block to method' do
      old = %{field :name, String do\n  property :full_name\nend}
      new = %{field :name, String, method: :full_name, null: true}
      assert_equal new, upgrade(old)
    end

    it "removes property when redundant" do
      old = %{field :name, String do\n  property "name" \nend}
      new = %{field :name, String, null: true}
      assert_equal new, upgrade(old)

      old = %{field :name, String, property: :name}
      new = %{field :name, String, null: true}
      assert_equal new, upgrade(old)

    end
  end

  describe "hash_key" do
    it "it moves configuration to kwarg"  do
      old = %{field :name, String do\n  hash_key :full_name\nend}
      new = %{field :name, String, hash_key: :full_name, null: true}
      assert_equal new, upgrade(old)
    end

    it "removes it if it's redundant" do
      old = %{field :name, String do\n  hash_key :name\nend}
      new = %{field :name, String, null: true}
      assert_equal new, upgrade(old)

      old = %{field :name, String, hash_key: :name}
      new = %{field :name, String, null: true}
      assert_equal new, upgrade(old)

      old = %{field :name, String do\n  hash_key "name"\nend}
      new = %{field :name, String, null: true}
      assert_equal new, upgrade(old)
    end
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
      assert_equal new, upgrade(old)
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
      assert_equal new, upgrade(old)
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
      assert_equal new, upgrade(old)

      old = %{
        UserInterface = GraphQL::InterfaceType.define do
          name "User"
        end
      }
      new = %{
        module UserInterface
          include Types::BaseInterface
          graphql_name "User"
        end
      }

      assert_equal new, upgrade(old)

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
      assert_equal new, upgrade(old)
    end
  end

  describe 'definition' do
    it 'upgrades the .define into class based definition' do
      old = %{UserType = GraphQL::ObjectType.define do
      end}
      new = %{class UserType < Types::BaseObject
      end}
      assert_equal new, upgrade(old)

      old = <<-RUBY
UserInterface = GraphQL::InterfaceType.define do
end
RUBY
      new = <<-RUBY
module UserInterface
  include Types::BaseInterface
end
RUBY

      assert_equal new, upgrade(old)

      old = %{UserUnion = GraphQL::UnionType.define do
      end}
      new = %{class UserUnion < Types::BaseUnion
      end}
      assert_equal new, upgrade(old)

      old = %{UserEnum = GraphQL::EnumType.define do
      end}
      new = %{class UserEnum < Types::BaseEnum
      end}
      assert_equal new, upgrade(old)

      old = %{UserInput = GraphQL::InputObjectType.define do
      end}
      new = %{class UserInput < Types::BaseInputObject
      end}
      assert_equal new, upgrade(old)

      old = %{UserScalar = GraphQL::ScalarType.define do
      end}
      new = %{class UserScalar < Types::BaseScalar
      end}
      assert_equal new, upgrade(old)
    end

    it 'upgrades including the module' do
      old = %{Module::UserType = GraphQL::ObjectType.define do
      end}
      new = %{class Module::UserType < Types::BaseObject
      end}
      assert_equal new, upgrade(old)
    end
  end

  describe 'fields' do
    it 'underscorizes field name' do
      old = %{field :firstName, !types.String}
      new = %{field :first_name, String, null: false}
      assert_equal new, upgrade(old)
    end

    describe "resolve proc to method" do
      it "converts object and context" do
        old = %{
          field :firstName, !types.String do
            resolve ->(obj, arg, ctx) {
              ctx.something
              other_ctx # test combined identifiers

              obj[ctx] + obj
              obj.given_name
            }
          end
        }
        new = %{
          field :first_name, String, null: false

          def first_name
            context.something
            other_ctx # test combined identifiers

            object[context] + object
            object.given_name
          end
        }
        assert_equal new, upgrade(old)
      end

      it "handles `_` var names" do
        old = %{
          field :firstName, !types.String do
            resolve ->(obj, _, _) {
              obj.given_name
            }
          end
        }
        new = %{
          field :first_name, String, null: false

          def first_name
            object.given_name
          end
        }
        assert_equal new, upgrade(old)
      end

      it "creates **arguments if necessary" do
        old = %{
          field :firstName, !types.String do
            argument :ctx, types.String, default_value: "abc"
            resolve ->(obj, args, ctx) {
              args[:ctx]
            }
          end
        }
        new = %{
          field :first_name, String, null: false do
            argument :ctx, String, default_value: "abc", required: false
          end

          def first_name(**args)
            args[:ctx]
          end
        }
        assert_equal new, upgrade(old)
      end

      it "fixes argument access: string -> sym, camel -> underscore" do
        old = %{
          field :firstName, !types.String do
            argument :someArg, types.String, default_value: "abc"
            argument :someArg2, types.String, default_value: "abc"
            resolve ->(obj, args, ctx) {
              args["someArg"] if args.key?("someArg")
              args[:someArg2]
            }
          end
        }
        new = %{
          field :first_name, String, null: false do
            argument :some_arg, String, default_value: "abc", required: false
            argument :some_arg2, String, default_value: "abc", required: false
          end

          def first_name(**args)
            args[:some_arg] if args.key?(:some_arg)
            args[:some_arg2]
          end
        }
        assert_equal new, upgrade(old)
      end
    end


    it 'upgrades to the new definition' do
      old = %{field :name, !types.String}
      new = %{field :name, String, null: false}
      assert_equal new, upgrade(old)

      old = %{field :name, !types.String, "description", method: :name_full}
      new = %{field :name, String, "description", method: :name_full, null: false}
      assert_equal new, upgrade(old)

      old = %{field :name, -> { !types.String }}
      new = %{field :name, String, null: false}
      assert_equal new, upgrade(old)

      old = %{connection :name, Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", null: true, connection: true}
      assert_equal new, upgrade(old)

      old = %{connection :name, !Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", null: false, connection: true}
      assert_equal new, upgrade(old)

      old = %{field :names, types[!types.String]}
      new = %{field :names, [String], null: true}
      assert_equal new, upgrade(old)

      old = %{field :names, !types[types.String]}
      new = %{field :names, [String, null: true], null: false}
      assert_equal new, upgrade(old)

      old = %{
        field :name, types.String do
        end
      }
      new = %{
        field :name, String, null: true
      }
      assert_equal new, upgrade(old)

      old = %{
        field :name, !types.String do
          description "abc"
        end

        field :name2, !types.Int do
          description "def"
        end
      }
      new = %{
        field :name, String, description: "abc", null: false

        field :name2, Integer, description: "def", null: false
      }
      assert_equal new, upgrade(old)

      old = %{
        field :name, -> { !types.String } do
        end
      }
      new = %{
        field :name, String, null: false
      }
      assert_equal new, upgrade(old)

      old = %{
        field :name do
          type -> { String }
        end
      }
      new = %{
        field :name, String, null: true
      }
      assert_equal new, upgrade(old)

      old = %{
        field :name do
          type !String
        end

        field :name2 do
          type !String
        end
      }
      new = %{
        field :name, String, null: false

        field :name2, String, null: false
      }
      assert_equal new, upgrade(old)

      old = %{
        field :name, -> { types.String },
          "newline description" do
        end
      }
      new = %{
        field :name, String, "newline description", null: true
      }
      assert_equal new, upgrade(old)

      old = %{
        field :name, -> { !types.String },
          "newline description" do
        end
      }
      new = %{
        field :name, String, "newline description", null: false
      }
      assert_equal new, upgrade(old)

      old = %{
       field :name, String,
         field: SomeField do
       end
      }
      new = %{
       field :name, String, field: SomeField, null: true
      }
      assert_equal new, upgrade(old)
    end
  end

  describe 'multi-line field with property/method' do
    it 'upgrades without breaking syntax' do
      old = %{
        field :is_example_field, types.Boolean,
          property: :example_field?
      }
      new = %{
        field :is_example_field, Boolean, method: :example_field?, null: true
      }

      assert_equal new, upgrade(old)
    end
  end

  describe 'multi-line connection with property/method' do
    it 'upgrades without breaking syntax' do
      old = %{
        connection :example_connection, -> { ExampleConnectionType },
          property: :example_connections
      }
      new = %{
        field :example_connection, ExampleConnectionType, method: :example_connections, null: true, connection: true
      }

      assert_equal new, upgrade(old)
    end
  end

  describe 'input_field' do
    it 'upgrades to argument' do
      old = %{input_field :id, !types.ID}
      new = %{argument :id, ID, required: true}
      assert_equal new, upgrade(old)
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
      assert_equal new, upgrade(old)
    end
  end

  describe "fixtures" do
    class ActiveRecordTypeToClassTransform < GraphQL::Upgrader::Transform
      def initialize
        @find_pattern = /^( +)([a-zA-Z_0-9:]*) = define_active_record_type\(-> ?\{ ?:{0,2}([a-zA-Z_0-9:]*) ?\} ?\) do/
        @replace_pattern = "\\1class \\2 < Platform::Objects::Base\n\\1  model_name \"\\3\""
      end

      def apply(input_text)
        input_text.sub(@find_pattern, @replace_pattern)
      end
    end

    # Modify the default output to match the custom structure
    class InputObjectsToInputsTransform < GraphQL::Upgrader::Transform
      def apply(input_text)
        input_text.gsub("Platform::InputObjects::", "Platform::Inputs::")
      end
    end

    def custom_upgrade(original_text)
      # Replace the default one with a custom one:
      type_transforms = GraphQL::Upgrader::Member::DEFAULT_TYPE_TRANSFORMS.map { |t|
        if t == GraphQL::Upgrader::TypeDefineToClassTransform
          GraphQL::Upgrader::TypeDefineToClassTransform.new(base_class_pattern: "Platform::\\3s::Base")
        else
          t
        end
      }

      type_transforms.unshift(ActiveRecordTypeToClassTransform)
      type_transforms.push(InputObjectsToInputsTransform)
      field_transforms = GraphQL::Upgrader::Member::DEFAULT_FIELD_TRANSFORMS.dup
      field_transforms.unshift(GraphQL::Upgrader::ConfigurationToKwargTransform.new(kwarg: "visibility"))
      upgrader = GraphQL::Upgrader::Member.new(original_text, type_transforms: type_transforms, field_transforms: field_transforms)
      upgrader.upgrade
    end

    original_files = Dir.glob("spec/fixtures/upgrader/*.original.rb")
    original_files.each do |original_file|
      transformed_file = original_file.sub(".original.", ".transformed.")
      original_text = File.read(original_file)
      expected_text = File.read(transformed_file)

      it "transforms #{original_file} -> #{transformed_file}" do
        transformed_text = custom_upgrade(original_text)
        assert_equal(expected_text, transformed_text)
      end

      it "is idempotent on #{transformed_file}" do
        retransformed_text = custom_upgrade(expected_text)
        assert_equal(expected_text, retransformed_text)
      end
    end
  end
end
