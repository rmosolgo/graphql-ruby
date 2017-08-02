# frozen_string_literal: true
module GraphQL
  class Object
    # @return [Object] The runtime object that this proxy wraps
    attr_reader :__proxied_object

    def initialize(obj, ctx)
      @__proxied_object = obj
      @__context = ctx
    end
  end
end
