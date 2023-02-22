# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasDeprecationReason
        # @return [String, nil] Explains why this member was deprecated (if present, this will be marked deprecated in introspection)
        def deprecation_reason
          @deprecation_reason
        end

        # Set the deprecation reason for this member, or remove it by assigning `nil`
        # @param text [String, nil]
        def deprecation_reason=(text)
          if text.nil?
            remove_directive(GraphQL::Schema::Directive::Deprecated)
          else
            if defined?(@deprecation_reason) && @deprecation_reason
              remove_directive(GraphQL::Schema::Directive::Deprecated)
            end
            @deprecation_reason = text
            directive(GraphQL::Schema::Directive::Deprecated, reason: text)
          end
        end
      end
    end
  end
end
