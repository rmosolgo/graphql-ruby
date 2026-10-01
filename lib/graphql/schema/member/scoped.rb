# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module Scoped
        # This is called when a field has `scope: true`.
        # The field's return type class receives this call.
        #
        # By default, it's a no-op. Override it to scope your objects.
        #
        # **Parameters**
        #
        # - `items` (`Object`) — Some list-like object (eg, Array, ActiveRecord::Relation)
        # - `context` (`GraphQL::Query::Context`)
        #
        # **Returns**
        #
        # - `Object` — Another list-like object, scoped to the current context
        #
        # :call-seq:
        #   scope_items(Object items, GraphQL::Query::Context context) -> Object
        def scope_items(items, context)
          items
        end

        def reauthorize_scoped_objects(new_value = nil)
          if new_value.nil?
            if @reauthorize_scoped_objects != nil
              @reauthorize_scoped_objects
            else
              find_inherited_value(:reauthorize_scoped_objects, true)
            end
          else
            @reauthorize_scoped_objects = new_value
          end
        end

        def inherited(subclass)
          super
          subclass.class_exec do
            @reauthorize_scoped_objects = nil
          end
        end
      end
    end
  end
end
