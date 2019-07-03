# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module ValidatesInput
        def valid_input?(val, ctx)
          validate_input(val, ctx).valid?
        end
      end
    end
  end
end
