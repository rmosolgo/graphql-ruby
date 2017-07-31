# frozen_string_literal: true
module GraphQL
  class Schema
    class Implementation
      # When no method is defined, we do this
      class PublicSendImplementation
        def initialize(method:)
          @method_name = method
        end

        # TODO compile this method?
        def call(obj, args, ctx)
          obj.object.public_send(@method_name)
        end
      end
    end
  end
end
