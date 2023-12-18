# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Testing::Helpers do
  class AssertionsSchema < GraphQL::Schema
    class BillSource < GraphQL::Dataloader::Source
      def fetch(students)
        students.map { |s| { amount: 1_000_001 } }
      end
    end

    class TuitionBill < GraphQL::Schema::Object
      def self.visible?(ctx)
        ctx[:current_user]&.admin?
      end

      field :amount_in_cents, Int, hash_key: :amount
    end

    class Transcript < GraphQL::Schema::Object
      def self.authorized?(object, context)
        (current_user = context[:current_user]) &&
            (admin_for = current_user[:admin_for]) &&
            (admin_for.include?(object && object["name"]))
      end

      field :gpa, Float
    end

    class Student < GraphQL::Schema::Object
      field :name, String do
        argument :full_name, Boolean, required: false
      end

      def name(full_name: nil)
        name = object["name"]
        if full_name
          "#{name} Mc#{name}"
        else
          name
        end
      end

      field :latest_bill, TuitionBill

      def latest_bill
        dataloader.with(BillSource).load(object)
      end

      field :is_admin_for, Boolean
      def is_admin_for
        (list = context[:admin_for]) && list.include?(object["name"])
      end

      field :transcript, Transcript, resolver_method: :object
    end

    class Query < GraphQL::Schema::Object
      field :students, [Student]
    end

    query(Query)
    use GraphQL::Dataloader
    lazy_resolve Proc, :call

    def self.resolve_type(abs_type, obj, ctx)
      case obj.type
      when :student
        -> { Student }
      when :tuition_bill
        TuitionBill
      else
        raise "Unexpected object: #{object.inspect}"
      end
    end

    def self.unauthorized_object(err)
      raise err
    end
  end

  include GraphQL::Testing::Helpers

  let(:admin_context) { { current_user: OpenStruct.new(admin?: true) } }

  describe "top-level helpers" do
    describe "run_graphql_field" do
      it "resolves fields" do
        assert_equal "Blah", run_graphql_field(AssertionsSchema, "Student.name", { "name" => "Blah" })
        assert_equal "Blah McBlah", run_graphql_field(AssertionsSchema, "Student.name", { "name" => "Blah" }, arguments: { "fullName" => true })
        assert_equal({ amount: 1_000_001 }, run_graphql_field(AssertionsSchema, "Student.latestBill", :student, context: admin_context))
      end

      it "works with resolution context" do
        with_resolution_context(AssertionsSchema, object: { "name" => "Foo" }, type: "Student", context: { admin_for: ["Foo"] }) do |rc|
          rc.run_graphql_field("name")
          rc.run_graphql_field("isAdminFor")
        end
      end

      it "raises an error when the type is hidden" do
        assert_equal 1_000_000, run_graphql_field(AssertionsSchema, "TuitionBill.amountInCents", { amount: 1_000_000 }, context: admin_context)

        err = assert_raises(GraphQL::Testing::Helpers::TypeNotVisibleError) do
          run_graphql_field(AssertionsSchema, "TuitionBill.amountInCents", { amount: 1_000_000 })
        end
        expected_message = "`TuitionBill` should be `visible?` this field resolution and `context`, but it was not"
        assert_equal expected_message, err.message
      end

      it "raises an error when the type isn't authorized" do
        err = assert_raises GraphQL::UnauthorizedError do
          run_graphql_field(AssertionsSchema, "Student.transcript.gpa", { gpa: 3.1 })
        end
        assert_equal "An instance of Hash failed Transcript's authorization check", err.message

        assert_equal 3.1, run_graphql_field(AssertionsSchema, "Student.transcript.gpa", { gpa: 3.1, "name" => "Jim" }, context: { current_user: OpenStruct.new(admin_for: ["Jim"])})
      end

      it "works with field extensions"
      it "prepares arguments"
      it "handles unauthorized field errors"
      it "raises when the type doesn't exist"
      it "raises when the field doesn't exist"
    end
  end

  describe "schema-level helpers" do
    include GraphQL::Testing::Helpers.for(AssertionsSchema)

    it "resolves fields" do
      assert_equal 5, run_graphql_field("TuitionBill.amountInCents", { amount: 5 }, context: admin_context)
    end

    it "works with resolution context" do
      with_resolution_context(object: { "name" => "Foo" }, type: "Student", context: { admin_for: ["Bar"] }) do |rc|
        assert_equal "Foo", rc.run_graphql_field("name")
        assert_equal false, rc.run_graphql_field("isAdminFor")
      end
    end
  end
end
