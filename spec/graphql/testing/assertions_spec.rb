# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Testing::Assertions do
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

    class Student < GraphQL::Schema::Object
      field :name, String
      field :latest_bill, TuitionBill

      def latest_bill
        dataloader.with(BillSource).load(object)
      end
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
  end

  include GraphQL::Testing::Assertions

  let(:admin_context) { { current_user: OpenStruct.new(admin?: true) } }

  describe "top-level assertions" do
    describe "assert_resolves_type_to" do
      it "tests resolving types" do
        assert_resolves_type_to AssertionsSchema, AssertionsSchema::Student, OpenStruct.new(type: :student)
        assert_resolves_type_to AssertionsSchema, nil, OpenStruct.new(type: :tuition_bill)
        assert_resolves_type_to AssertionsSchema, AssertionsSchema::TuitionBill, OpenStruct.new(type: :tuition_bill), context: admin_context
      end

      it "raises when the types don't match" do
        err = assert_raises(Minitest::Assertion) do
          assert_resolves_type_to AssertionsSchema, AssertionsSchema::TuitionBill, OpenStruct.new(type: :student)
        end
        expected_message = <<~ERR
        AssertionsSchema resolves #<OpenStruct type=:student> to AssertionsSchema::TuitionBill.
        --- expected
        +++ actual
        @@ -1 +1 @@
        -AssertionsSchema::TuitionBill
        +AssertionsSchema::Student
        ERR
        assert_equal expected_message, err.message
      end

      it "raises when the type is not `.visible?`" do
        err = assert_raises(Minitest::Assertion) do
          assert_resolves_type_to AssertionsSchema, AssertionsSchema::TuitionBill, OpenStruct.new(type: :tuition_bill)
        end

        expected_message = <<~ERR
        AssertionsSchema resolves #<OpenStruct type=:tuition_bill> to AssertionsSchema::TuitionBill (`TuitionBill` was not `visible?` for this `context`).
        --- expected
        +++ actual
        @@ -1 +1 @@
        -AssertionsSchema::TuitionBill
        +nil
        ERR

        assert_equal expected_message, err.message
      end
    end

    describe "assert_resolves_field_to" do
      it "resolves fields" do
        assert_resolves_field_to AssertionsSchema, "Blah", AssertionsSchema::Student, "name", { "name" => "Blah"}
        assert_resolves_field_to AssertionsSchema, "Blah", "Student", "name", { "name" => "Blah"}
        assert_resolves_field_to(AssertionsSchema, { amount: 1_000_001 }, "Student", "latestBill", :student, context: admin_context)
      end

      it "raises an error when the return value doesn't match" do
        err = assert_raises(Minitest::Assertion) do
          assert_resolves_field_to AssertionsSchema, "Blah", "Student", "name", { "name" => "Foo"}
        end
        expected_message = <<~ERR
        Student.name resolved to "Blah" for {"name"=>"Foo"}.
        --- expected
        +++ actual
        @@ -1 +1 @@
        -"Blah"
        +"Foo"
        ERR
        assert_equal expected_message, err.message
      end

      it "raises an error when the type is hidden" do
        assert_resolves_field_to AssertionsSchema, 1_000_000, "TuitionBill", "amountInCents", { amount: 1_000_000 }, context: admin_context

        err = assert_raises(Minitest::Assertion) do
          assert_resolves_field_to AssertionsSchema, "Blah", "TuitionBill", "amountInCents", { amount: 1_000_000 }
        end
        expected_message = "`TuitionBill` should be `visible?` this field resolution and `context`, but it was not"
        assert_equal expected_message, err.message
      end
    end
  end

  describe "schema-level assertions" do
    include GraphQL::Testing::Assertions.for(AssertionsSchema)

    it "tests resolving types" do
      assert_resolves_type_to AssertionsSchema::Student, OpenStruct.new(type: :student)
    end

    it "tests resolving fields" do
      assert_resolves_field_to 5, "TuitionBill", "amountInCents", { amount: 5 },
        context: admin_context
    end
  end
end
