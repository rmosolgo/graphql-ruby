# frozen_string_literal: true
# helpers to enable / disable error bubbling in a block scope.
#
# Some schemas are made with `.define`, others are `class`, so we have to support both.
module ErrorBubblingHelpers
  def without_error_bubbling(schema)
    original_error_bubbling = !!schema.error_bubbling
    begin
      if schema.is_a?(Class)
        schema.error_bubbling(false)
      end
      yield if block_given?
    ensure
      if schema.is_a?(Class)
        schema.error_bubbling(original_error_bubbling)
      end
    end
  end

  def with_error_bubbling(schema)
    original_error_bubbling = !!schema.error_bubbling
    begin
      if schema.is_a?(Class)
        schema.error_bubbling(true)
      end
      yield if block_given?
    ensure
      if schema.is_a?(Class)
        schema.error_bubbling(original_error_bubbling)
      end
    end
  end
end
