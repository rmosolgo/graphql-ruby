# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::String do
  let(:string_type) { GraphQL::Types::String }

  it "is a default scalar" do
    assert_equal(true, string_type.default_scalar?)
  end

  describe "coerce_result" do
    let(:utf_8_str) { "foobar" }
    let(:ascii_str) { "foobar".encode(Encoding::ASCII_8BIT) }
    let(:binary_str) { "\0\0\0foo\255\255\255".dup.force_encoding("BINARY") }
    let(:invalid_utf_8_str) { "\xFF".dup.force_encoding(Encoding::UTF_8) }

    describe "encoding" do
      subject { string_type.coerce_isolated_result(string) }

      describe "when result is encoded as UTF-8" do
        let(:string) { utf_8_str }

        it "returns the string" do
          assert_equal subject, string
        end
      end

      describe "when the result is not UTF-8 but can be transcoded" do
        let(:string) { ascii_str }

        it "returns the string transcoded to UTF-8" do
          assert_equal subject, string.encode(Encoding::UTF_8)
        end
      end

      it "rejects invalid UTF-8 strings" do
        [invalid_utf_8_str, invalid_utf_8_str.dup.freeze].each do |string|
          err = assert_raises(GraphQL::StringEncodingError) { string_type.coerce_isolated_result(string) }

          assert_same string, err.string
          assert_equal 'String "\xFF" was encoded as UTF-8. GraphQL requires an encoding compatible with UTF-8.', err.message
        end
      end

      it "transcodes strings without modifying the original" do
        [false, true].each do |frozen|
          string = "café".encode(Encoding::ISO_8859_1)
          original_bytes = string.bytes
          string.freeze if frozen

          result = string_type.coerce_isolated_result(string)

          assert_equal "café", result
          assert_equal Encoding::UTF_8, result.encoding
          assert_equal Encoding::ISO_8859_1, string.encoding
          assert_equal original_bytes, string.bytes
        end
      end

      describe "when the result is not UTF-8 and cannot be transcoded" do
        let(:string) { binary_str }

        it "raises GraphQL::StringEncodingError" do
          err = assert_raises(GraphQL::StringEncodingError) { subject }
          assert_equal "String \"\\x00\\x00\\x00foo\\xAD\\xAD\\xAD\" was encoded as ASCII-8BIT. GraphQL requires an encoding compatible with UTF-8.", err.message
          assert_equal string, err.string
        end
      end

      describe "In queries" do
        let(:schema) {
          query_type = Class.new(GraphQL::Schema::Object) do
            graphql_name "Query"

            field :utf8_string, String, hash_key: :utf8_string
            field :good_string, String, hash_key: :good_string
            field :bad_string, String, resolve_static: true
            def self.bad_string(context)
              "\0\0\0foo\255\255\255".dup.force_encoding("BINARY")
            end

            def bad_string
              self.class.bad_string(nil)
            end
          end

          Class.new(GraphQL::Schema) do
            query(query_type)
          end
        }

        it "includes location in the error message" do
          err = assert_raises GraphQL::StringEncodingError do
            schema.execute("{ badString }")
          end
          expected_err = exec_next_error_message "Query.badString", "String \"\\x00\\x00\\x00foo\\xAD\\xAD\\xAD\" was encoded as ASCII-8BIT#{if_exec_next("", " @ badString (Query.badString)")}. GraphQL requires an encoding compatible with UTF-8."
          assert_equal expected_err, err.message
        end

        it "raises a type error for invalid UTF-8 before JSON serialization" do
          err = assert_raises(GraphQL::StringEncodingError) do
            schema.execute("{ utf8String }", root_value: { utf8_string: invalid_utf_8_str })
          end

          assert_same invalid_utf_8_str, err.string
        end

        it "lets a custom handler return a field error for invalid UTF-8" do
          handled_schema = Class.new(schema) do
            def self.type_error(err, ctx)
              if err.is_a?(GraphQL::StringEncodingError)
                ctx[:encoding_errors] << err
                raise GraphQL::ExecutionError, "Invalid string encoding"
              else
                super
              end
            end
          end
          errors = []
          result = handled_schema.execute(
            "{ bad: utf8String goodString }",
            root_value: { utf8_string: invalid_utf_8_str, good_string: "ok" },
            context: { encoding_errors: errors },
          )

          assert_equal({ "bad" => nil, "goodString" => "ok" }, JSON.parse(result.to_json)["data"])
          assert_equal 1, result["errors"].size
          assert_equal "Invalid string encoding", result["errors"].first["message"]
          assert_equal ["bad"], result["errors"].first["path"]
          assert_equal 1, errors.size
          assert_same invalid_utf_8_str, errors.first.string
        end
      end
    end

    describe "when the schema defines a custom handler" do
      let(:schema) {
        Class.new(GraphQL::Schema) do
          def self.type_error(err, ctx)
            ctx.errors << err
            "🌾"
          end
        end
      }

      let(:context) {
        OpenStruct.new(schema: schema, errors: [])
      }

      it "calls the handler" do
        assert_equal "🌾", string_type.coerce_result(binary_str, context)
        err = context.errors.last
        assert_instance_of GraphQL::StringEncodingError, err
      end

      it "uses the handler's replacement for invalid UTF-8" do
        assert_equal "🌾", string_type.coerce_result(invalid_utf_8_str, context)
        assert_instance_of GraphQL::StringEncodingError, context.errors.last
        assert_same invalid_utf_8_str, context.errors.last.string
      end
    end
  end

  describe "coerce_input" do
    it "accepts strings" do
      assert_equal "str", string_type.coerce_isolated_input("str")
    end

    it "doesn't accept other types" do
      assert_nil string_type.coerce_isolated_input(100)
      assert_nil string_type.coerce_isolated_input(true)
      assert_nil string_type.coerce_isolated_input(0.999)
    end
  end


  describe "unicode escapes" do
    class UnicodeEscapeSchema < GraphQL::Schema
      class QueryType < GraphQL::Schema::Object
        field :get_string, String, resolve_static: true do
          argument :string, String
        end

        def self.get_string(context, string:)
          string
        end

        def get_string(string:)
          self.class.get_string(context, string: string)
        end
      end

      query(QueryType)
    end

    it "parses escapes properly in single-quoted strings" do
      query_str = File.read("./spec/fixtures/unicode_escapes/query1.graphql")
      res = UnicodeEscapeSchema.execute(query_str)
      assert_equal "d", res["data"]["example1"]
      assert_equal "\\u0064", res["data"]["example2"]
      assert_equal "\\u006", res["data"]["example4"]

      error_query_str = query_str.gsub("  # ", "  ")
      res2 = UnicodeEscapeSchema.execute(error_query_str)
      expected_err = if USING_C_PARSER
        "syntax error, unexpected invalid token (\"\\\"\") at [4, 31]"
      else
        "Expected string or block string, but it was malformed"
      end
      assert_equal [expected_err], res2["errors"].map { |err| err["message"] }
    end

    it "parses escapes properly in triple-quoted strings" do
      query_str = File.read("./spec/fixtures/unicode_escapes/query2.graphql")
      res = UnicodeEscapeSchema.execute(query_str)
      # No replacing in block strings:
      assert_equal "\\a", res["data"]["example1"]
      assert_equal "\\u006", res["data"]["example2"]
      assert_equal "\\n", res["data"]["example3"]
      assert_equal "\\u0064", res["data"]["example4"]
    end
  end
end
