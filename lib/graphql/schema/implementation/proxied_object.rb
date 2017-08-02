# frozen_string_literal: true
module GraphQL
  class Schema
    class Implementation
      # Object + implementation proxy
      # basically 2-tuple, but this is what we got.
      class ProxiedObject
        attr_reader :object, :proxy
        def initialize(object, proxy)
          @object = object
          @proxy = proxy
        end
      end
    end
  end
end
