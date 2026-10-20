# frozen_string_literal: true
# typed: true

module GraphQL
  class Schema
    class Member
      #--
      # @requires_ancestor: Kernel
      module HasPath
        # **Returns**
        #
        # - `String` — A description of this member's place in the GraphQL schema
        #
        # :call-seq:
        #   path() -> String
        def path
          member = self #: untyped
          path_str = if member.respond_to?(:graphql_name)
            member.graphql_name
          elsif self.class.respond_to?(:graphql_name)
            # Instances of resolvers
            self.class.graphql_name
          end

          if member.respond_to?(:owner) && member.owner.respond_to?(:path)
            path_str = "#{member.owner.path}.#{path_str}"
          end

          path_str
        end
      end
    end
  end
end
