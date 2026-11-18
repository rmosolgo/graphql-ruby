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

    describe "input object types" do
      let(:context) { GraphQL::Query::NullContext.instance }
      let(:plain_input) do
        Class.new(GraphQL::Schema::InputObject) do
          graphql_name "PlainInput"
          argument :value, String
        end
      end

      it "is false without an authorization hook" do
        refute GraphQL::Schema::InputObject.authorizes?(context)
        refute plain_input.authorizes?(context)
        refute Class.new(plain_input).authorizes?(context)
      end

      it "detects direct and inherited authorization hooks" do
        input = Class.new(plain_input) do
          def self.authorized?(object, value, context)
            false
          end
        end
        assert input.authorizes?(context)
        assert Class.new(input).authorizes?(context)
        assert Class.new(plain_input) { extend HasAuthorization::DefinesAuthorized }.authorizes?(context)
      end

      it "checks visible argument authorization hooks" do
        input = Class.new(plain_input) do
          argument_class HasAuthorization::DirectAuthorizedObject::DirectAuthorizedArgument
          argument :secret, String
        end
        visible_context = GraphQL::Query.new(HasAuthorization::Schema, "{ __typename }").context
        hidden_context = GraphQL::Query.new(HasAuthorization::Schema, "{ __typename }", context: { hide_arg: true }).context
        assert input.authorizes?(visible_context)
        refute input.authorizes?(hidden_context)
      end

      it "checks nested input objects and lists" do
        input = plain_input
        wrapper = Class.new(plain_input) { argument :nested, [input] }
        refute wrapper.authorizes?(context)

        input.extend(HasAuthorization::DefinesAuthorized)
        assert wrapper.authorizes?(context)
      end

      it "handles recursive inputs without authorization hooks" do
        input = Class.new(plain_input) { argument :nested, [self], required: false }
        refute input.authorizes?(context)
      end

      it "finds authorization hooks after a recursive reference" do
        input = Class.new(plain_input) do
          argument :nested, self, required: false
          argument_class HasAuthorization::IndirectAuthorizedObject::IndirectAuthorizedArgument
          argument :secret, String
        end
        assert input.authorizes?(context)
      end

      it "checks mutually recursive inputs from either entry point" do
        left = Class.new(plain_input)
        right = Class.new(plain_input)
        left.argument :right, right, required: false
        right.argument :left, left, required: false
        refute left.authorizes?(context)
        refute right.authorizes?(context)

        left.argument_class HasAuthorization::IndirectAuthorizedObject::IndirectAuthorizedArgument
        left.argument :secret, String
        assert left.authorizes?(context)
        assert right.authorizes?(context)
      end

      it "keeps authorization enabled for recursive custom input predicates" do
        input = Class.new(plain_input) do
          argument :nested, self, required: false

          def self.authorizes?(context)
            super
          end
        end
        assert input.authorizes?(context)
      end

      it "keeps authorization enabled for recursive custom argument predicates" do
        input = Class.new(plain_input) do
          argument_class(Class.new(GraphQL::Schema::Argument) do
            def authorizes?(context)
              super
            end
          end)
          argument :nested, self, required: false
        end
        assert input.authorizes?(context)
      end

      it "keeps authorization enabled for mutually recursive custom input predicates" do
        left, right = 2.times.map do
          Class.new(plain_input) do
            def self.authorizes?(context)
              super
            end
          end
        end
        left.argument :right, right, required: false
        right.argument :left, left, required: false
        assert left.authorizes?(context)
        assert right.authorizes?(context)
      end

      it "keeps authorization enabled for mutually recursive custom argument predicates" do
        custom_argument = Class.new(GraphQL::Schema::Argument) do
          def authorizes?(context)
            super
          end
        end
        left, right = 2.times.map { Class.new(plain_input) { argument_class custom_argument } }
        left.argument :right, right, required: false
        right.argument :left, left, required: false
        assert left.authorizes?(context)
        assert right.authorizes?(context)
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
