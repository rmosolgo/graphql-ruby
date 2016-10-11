module GraphQL
  class Schema
    # This object can restrict access to schema members on a query-by-query basis.
    #
    # @example Hidding private fields
    #   public_only = GraphQL::Schema::Mask.new { |member| member.metadata[:private] }
    #   result = Schema.execute(query_string, mask: public_only)
    #
    # @example Custom mask implementation
    #   # Define a mask to use instead of {Schema::Mask}.
    #   # It must respond to `#visible?(member)`.
    #   class FlagsMask
    #     def initialize(user)
    #       @user = user
    #     end
    #
    #     # Require that the user has any applicable flags
    #     def visible?(member)
    #       member.metadata[:required_flags].all do |flag|
    #         @user.has_flag?(flag)
    #       end
    #     end
    #   end
    #
    #   # Then, use the custom mask in query:
    #   flags_mask = FlagsMask.new(current_user)
    #
    #   # This query can only access members which match the user's flags
    #   result = Schema.execute(query_string, mask: flags_mask)
    #
    class Mask
      # Make a new mask which hides some members of the schema.
      #
      # @param block Schema members will be hidden when the block returns true
      def initialize(&block)
        @filter = block
      end

      def visible?(member)
        !@filter.call(member)
      end

      # A Mask implementation that shows everything as visible
      module NullMask
        module_function

        def visible?(member)
          true
        end
      end
    end
  end
end
