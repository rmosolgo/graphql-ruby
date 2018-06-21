# frozen_string_literal: true
module GraphQL
  class UnauthorizedError < GraphQL::Error
    # @return [Object] the application object that failed the authorization check
    attr_reader :object

    # @return [Class] the GraphQL object type whose `.authorized?` method was called (and returned false)
    attr_reader :type

    # @return [GraphQL::Query::Context] the context for the current query
    attr_reader :context

    def initialize(message = nil, object: nil, type: nil, context: nil)
      if message.nil? && object.nil?
        raise ArgumentError, "#{self.class.name} requires either a message or keywords"
      end

      @object = object
      @type = type
      @context = context
      message ||= "An instance of #{object.class} failed #{type.name}'s authorization check"
      super(message)
    end
  end
end
