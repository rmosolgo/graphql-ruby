# frozen_string_literal: true
require "spec_helper"

describe "Next Execution object authorization" do
  class NextObjectAuthorizationSchema < GraphQL::Schema
    class LazyAuth
      def initialize(&block)
        @block = block
      end

      def value
        @block.call
      end
    end

    class AuthBackendDown < StandardError; end
    class RescuedToTrue < StandardError; end

    class Document < GraphQL::Schema::Object
      field :title, String, hash_key: :title

      def self.authorized?(object, context)
        return true unless object[:private]

        case context[:mode]
        when :return_false then false
        when :raise_unauthorized then raise GraphQL::UnauthorizedError.new(object: object, type: self, context: context)
        when :raise_execution_error then raise GraphQL::ExecutionError, "not allowed"
        when :raise_rescued_to_true then raise RescuedToTrue
        when :lazy_false then LazyAuth.new { false }
        when :lazy_unauthorized then LazyAuth.new { raise GraphQL::UnauthorizedError.new(object: object, type: self, context: context) }
        when :lazy_execution_error then LazyAuth.new { raise GraphQL::ExecutionError, "not allowed" }
        when :lazy_backend_outage then LazyAuth.new { raise AuthBackendDown, "timeout" }
        else raise ArgumentError, "Unknown mode: #{context[:mode].inspect}"
        end
      end
    end

    class Query < GraphQL::Schema::Object
      field :documents, [Document, null: true], hash_key: :documents
      field :non_null_documents, [Document], hash_key: :documents
      field :document, Document, null: false, hash_key: :document
    end

    query Query
    use GraphQL::Execution::Next
    lazy_resolve(LazyAuth, :value)
    rescue_from(AuthBackendDown) { raise GraphQL::ExecutionError, "authorization unavailable" }
    rescue_from(RescuedToTrue) { true }

    def self.unauthorized_object(err)
      err.context[:redact] ? { title: "REDACTED" } : nil
    end
  end

  ROOT_VALUE = {
    documents: [{ title: "public" }, { title: "SECRET", private: true }],
    document: { title: "SECRET", private: true },
  }.freeze

  MODES = %i[
    return_false raise_unauthorized raise_execution_error raise_rescued_to_true
    lazy_false lazy_unauthorized lazy_execution_error lazy_backend_outage
  ]

  QUERIES = [
    "{ documents { title } }",
    "{ nonNullDocuments { title } }",
    "{ document { title } }",
  ]

  def run_both(query_str, context)
    legacy = NextObjectAuthorizationSchema.execute(query_str, root_value: ROOT_VALUE, context: context.dup).to_h
    next_result = NextObjectAuthorizationSchema.execute_next(query_str, root_value: ROOT_VALUE, context: context.dup).to_h
    [legacy, next_result]
  end

  MODES.each do |mode|
    [false, true].each do |redact|
      it "matches the legacy runtime when authorized? uses #{mode} (redact: #{redact})" do
        QUERIES.each do |query_str|
          legacy, next_result = run_both(query_str, { mode: mode, redact: redact })
          assert_equal legacy, next_result, "#{query_str} should match"
          refute_includes next_result.inspect, "SECRET" unless mode == :raise_rescued_to_true
        end
      end
    end
  end

  it "continues resolving authorized siblings when authorized? raises an ExecutionError" do
    legacy, next_result = run_both("{ documents { title } }", { mode: :raise_execution_error })
    expected = {
      "errors" => [{ "message" => "not allowed", "locations" => [{ "line" => 1, "column" => 3 }], "path" => ["documents", 1] }],
      "data" => { "documents" => [{ "title" => "public" }, nil] },
    }
    assert_equal expected, legacy
    assert_equal expected, next_result
  end

  it "adds errors from lazy authorized? values instead of authorizing the object" do
    %i[lazy_execution_error lazy_backend_outage].each do |mode|
      _legacy, next_result = run_both("{ documents { title } }", { mode: mode })
      assert_equal [{ "title" => "public" }, nil], next_result["data"]["documents"]
      assert_equal 1, next_result["errors"].size
    end
  end

  it "uses the unauthorized_object replacement when authorized? raises UnauthorizedError" do
    %i[raise_unauthorized lazy_unauthorized].each do |mode|
      legacy, next_result = run_both("{ document { title } }", { mode: mode, redact: true })
      expected = { "data" => { "document" => { "title" => "REDACTED" } } }
      assert_equal expected, legacy, "legacy #{mode}"
      assert_equal expected, next_result, "next #{mode}"
    end
  end
end
