# frozen_string_literal: true
require "spec_helper"

describe "Logger" do
  describe "Schema.default_logger" do
    if defined?(Rails)
      it "When Rails is present, returns the Rails logger" do
        assert_equal Rails.logger, GraphQL::Schema.default_logger
      end
    else
      it "Without Rails, returns a new logger" do
        assert_instance_of Logger, GraphQL::Schema.default_logger
      end
    end

    it "can be overridden" do
      new_logger = Logger.new($stdout)
      schema = Class.new(GraphQL::Schema) do
        default_logger(new_logger)
      end
      assert_equal new_logger, schema.default_logger
    end

    it "can be set to a null logger with nil" do
      schema = Class.new(GraphQL::Schema)
      schema.default_logger(nil)
      nil_logger = schema.default_logger
      std_out, std_err = capture_io do
        nil_logger.error("Blah")
        nil_logger.warn("Something")
        nil_logger.log("Hi")
      end
      assert_equal "", std_out
      assert_equal "", std_err
    end
  end

  describe "during execution" do

    class LoggerSchema < GraphQL::Schema
      LOG_STRING = StringIO.new
      LOGGER = Logger.new(LOG_STRING)
      LOGGER.level = :debug

      module Node
        include GraphQL::Schema::Interface
        field :id, ID
      end

      class Query < GraphQL::Schema::Object
        field :node, Node do
          argument :id, ID
        end

        def node(id:)

        end
      end
      query(Query)
      default_logger(LOGGER)
    end

    before do
      LoggerSchema::LOG_STRING.truncate(0)
    end

    it "logs about hidden interfaces with no implementations" do
      res = LoggerSchema.execute("{ node(id: \"5\") { id } }")
      assert_equal ["Field 'node' doesn't exist on type 'Query'"], res["errors"].map { |err| err["message"] }
      assert_includes LoggerSchema::LOG_STRING.string, "Interface `Node` hidden because it has no visible implementors"
    end
  end
end
