# frozen_string_literal: true
module GraphQL
  class UnauthorizedError < GraphQL::Error
    # @return [Object] the application object that failed the authorization check
    attr_reader :object

    # @return [Class] the GraphQL object type whose `.authorized?` method was called (and returned false)
    attr_reader :type

    # @return [GraphQL::Query::Context] the context for the current query
    attr_reader :context

    def initialize(object:, type:, context:)
      @object = object
      @type = type
      @context = context
      super("An instance of #{object.class} failed #{type.name}'s authorization check")
    end
  end
end
