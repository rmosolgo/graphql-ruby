# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  class Schema
    class Member
      module HasAuthorization
        #: (Module[untyped] child_class) -> void
        def self.included(child_class)
          child_class.include(InstanceConfigured)
        end

        #: (Module[untyped] child_class) -> void
        def self.extended(child_class)
          child_class.extend(ClassConfigured)
          child_class.class_exec do
            @authorizes = false #: bool?
          end
        end

        #: (untyped object, GraphQL::Query::Context context) -> bool
        def authorized?(object, context)
          true
        end

        #--
        # @requires_ancestor: Kernel
        module InstanceConfigured
          #: (GraphQL::Query::Context context) -> bool
          def authorizes?(context)
            raise RequiredImplementationMissingError, "#{self.class} must implement #authorizes?(context)"
          end
        end

        #--
        # @requires_ancestor: Kernel
        module ClassConfigured
          #: (GraphQL::Query::Context context) -> bool
          def authorizes?(context)
            method(:authorized?).owner != GraphQL::Schema::Member::HasAuthorization
          end
        end
      end
    end
  end
end
