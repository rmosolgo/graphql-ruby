# frozen_string_literal: true
module GraphQL
  # By default, GraphQL objects are wrapped in subclasses of `GraphQL::Object`
  #
  # Your subclasses can:
  #
  # - Customize field execution by defining methods
  # - Share code via composition or inheritance
  # - Access the query context via `context`
  class Object
    # @return [Object] The runtime object that this proxy wraps
    attr_reader :__proxied_object
    alias :object :__proxied_object

    def initialize(obj, ctx)
      @__proxied_object = obj
      @__context = ctx
    end

    # @return [GraphQL::Query::Context] the query's `context:` values
    def context
      @__context
    end
  end
end
