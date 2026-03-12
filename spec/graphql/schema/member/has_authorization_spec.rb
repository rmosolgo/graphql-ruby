# frozen_string_literal: true
require "spec_helper"

describe 'Has Authorization' do
  module HasAuthorization
    class Schema < GraphQL::Schema
      use GraphQL::Schema::Visibility
    end
    module DefinesAuthorized
      def authorized?(*whatever)
        false
      end
    end

    class BaseArgument < GraphQL::Schema::Argument
    end

    class BaseField < GraphQL::Schema::Field
      argument_class BaseArgument
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
    end

    class UnauthorizedObject < BaseObject
      field :f, String do
        argument :a, String
      end
    end

    class DirectAuthorizedObject < BaseObject
      class DirectAuthorizedArgument < BaseArgument
        def authorized?(*whatever)
          false
        end

        def visible?(context)
          !context[:hide_arg]
        end
      end

      class DirectAuthorizedArgumentField < BaseField
        argument_class DirectAuthorizedArgument
      end
      field_class DirectAuthorizedArgumentField
      field :f, String do
        argument :a, String
      end
    end

    class IndirectAuthorizedObject < BaseObject
      class IndirectAuthorizedArgument < BaseArgument
        include DefinesAuthorized
      end

      class IndirectAuthorizedField < BaseField
        argument_class IndirectAuthorizedArgument
      end
      field_class IndirectAuthorizedField
      field :f, String do
        argument :a, String
      end
    end
  end
  describe "authorizes?" do
    describe "arguments" do
      it "is false when no custom authorized method" do
        assert_equal false, GraphQL::Introspection::EntryPoints.get_field("__type").get_argument("name").authorizes?({})
        test_obj = Class.new(GraphQL::Schema::Object) do
          field :f, String do
            argument :a, Integer
          end
        end
        assert_equal false, test_obj.get_field("f").get_argument("a").authorizes?({})
        assert_equal false, HasAuthorization::UnauthorizedObject.get_field("f").get_argument("a").authorizes?({})
      end

      it "is true when the argument class has an authorized? method" do
        assert_equal true, HasAuthorization::DirectAuthorizedObject.get_field("f").get_argument("a").authorizes?({})
      end

      it "is true when the argument class includes a module with an authorized? method" do
        assert_equal true, HasAuthorization::IndirectAuthorizedObject.get_field("f").get_argument("a").authorizes?({})
      end
    end

    describe "fields" do
      it "is false when no custom authorized method" do
        assert_equal false, GraphQL::Introspection::EntryPoints.get_field("__type").authorizes?(GraphQL::Query::NullContext.instance)
        test_obj = Class.new(GraphQL::Schema::Object) do
          field :f, String
        end
        assert_equal false, test_obj.get_field("f").authorizes?(GraphQL::Query::NullContext.instance)
        assert_equal false, HasAuthorization::UnauthorizedObject.get_field("f").authorizes?(GraphQL::Query::NullContext.instance)
      end

      it "is true when the field class has an authorized? method" do
        test_obj = Class.new(GraphQL::Schema::Object) do
          field_class(Class.new(GraphQL::Schema::Field) do
            def authorized?(*whatever)
              true
            end
          end)

          field :f, String
        end

        assert_equal true, test_obj.get_field("f").authorizes?(GraphQL::Query::NullContext.instance)
      end

      it "is true when the field superclass includes a module with def authorized?" do
        base_field = Class.new(GraphQL::Schema::Field) do
          include HasAuthorization::DefinesAuthorized
        end

        test_obj = Class.new(GraphQL::Schema::Object) do
          field_class(Class.new(base_field))

          field :f, String
        end

        assert_equal true, test_obj.get_field("f").authorizes?(GraphQL::Query::NullContext.instance)

      end
      it "is true when an argument has authorizes? => true" do
        assert_equal true, HasAuthorization::DirectAuthorizedObject.get_field("f").authorizes?(GraphQL::Query::NullContext.instance)
        assert_equal true, HasAuthorization::IndirectAuthorizedObject.get_field("f").authorizes?(GraphQL::Query::NullContext.instance)
      end

      it "is false when `authorizes?` arguments are hidden" do
        ctx = GraphQL::Query.new(HasAuthorization::Schema, "{ __typename }", context: { hide_arg: true }).context
        assert_equal false, HasAuthorization::DirectAuthorizedObject.get_field("f").authorizes?(ctx)
        assert_equal true, HasAuthorization::IndirectAuthorizedObject.get_field("f").authorizes?(ctx), "This argument isn't hidden"
      end
    end

    describe "object types" do
      it "is false when no method override is present in inheritance chain" do
        assert_equal false, GraphQL::Schema::Object.authorizes?({})
        assert_equal false, GraphQL::Introspection::EntryPoints.authorizes?({})
        test_obj = Class.new(GraphQL::Schema::Object)
        assert_equal false, test_obj.authorizes?({})
        assert_equal false, HasAuthorization::UnauthorizedObject.authorizes?({})
      end

      it "is true when a method override is directly present" do
        test_obj = Class.new(GraphQL::Schema::Object) do
          def self.authorized?(obj, ctx)
            :nothing
          end
        end
        assert_equal true, test_obj.authorizes?({})
      end

      it "is true when a method override is indirectly present" do
        test_obj = Class.new(GraphQL::Schema::Object) do
          extend HasAuthorization::DefinesAuthorized
        end
        assert_equal true, test_obj.authorizes?({})
        assert_equal true, Class.new(Class.new(test_obj)).authorizes?({})
      end
    end
  end
end
