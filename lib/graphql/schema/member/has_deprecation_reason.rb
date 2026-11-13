# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  class Schema
    class Member
      #--
      # @requires_ancestor: GraphQL::Schema::Member::HasDirectives
      module HasDeprecationReason
        # **Returns**
        #
        # - `String, nil` — Explains why this member was deprecated (if present, this will be marked deprecated in introspection)
        #: String?
        attr_reader :deprecation_reason

        # Set the deprecation reason for this member, or remove it by assigning `nil`
        #
        # **Parameters**
        #
        # - `text` (`String, nil`)
        #
        # :call-seq:
        #   deprecation_reason=(String | nil text)
        #: (String? text) -> void
        def deprecation_reason=(text)
          @deprecation_reason = text #: String?
          if text.nil?
            remove_directive(GraphQL::Schema::Directive::Deprecated)
          else
            # This removes a previously-attached directive, if there is one:
            directive(GraphQL::Schema::Directive::Deprecated, reason: text)
          end
        end

        #: (Module[untyped] child_class) -> void
        def self.extended(child_class)
          super
          child_class.extend(ClassMethods)
        end

        #--
        # @requires_ancestor: GraphQL::Schema::Member::HasDeprecationReason
        module ClassMethods
          #: (?untyped new_reason) -> String?
          def deprecation_reason(new_reason = NOT_CONFIGURED)
            if NOT_CONFIGURED.equal?(new_reason)
              super()
            else
              self.deprecation_reason = new_reason
            end
          end
        end
      end
    end
  end
end
