# frozen_string_literal: true
module ErrorBubblingHelpers
  def without_error_bubbling(schema)
    original_error_bubbling = schema.error_bubbling
    begin
      schema.error_bubbling = false
      yield if block_given?
    ensure
      schema.error_bubbling = original_error_bubbling
    end
  end

  def with_error_bubbling(schema)
    original_error_bubbling = schema.error_bubbling
    begin
      schema.error_bubbling = true
      yield if block_given?
    ensure
      schema.error_bubbling = original_error_bubbling
    end
  end
end