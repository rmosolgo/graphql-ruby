# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasDeprecationReason
        # @return [String, nil] Explains why this member was deprecated (if present, this will be marked deprecated in introspection)
        def deprecation_reason
          dir = self.directives.find { |d| d.is_a?(GraphQL::Schema::Directive::Deprecated) }
          dir && dir.arguments[:reason]
        end

        # Set the deprecation reason for this member, or remove it by assigning `nil`
        # @param text [String, nil]
        def deprecation_reason=(text)
          if text.nil?
            remove_directive(GraphQL::Schema::Directive::Deprecated)
          else
            directive(GraphQL::Schema::Directive::Deprecated, reason: text)
          end
        end
      end
    end
  end
end
