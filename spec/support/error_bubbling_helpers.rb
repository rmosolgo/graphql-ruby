module ErrorBubblingHelpers
  def error_bubbling_disabled(schema)
    original_error_bubbling = schema.disable_error_bubbling
    begin
      schema.disable_error_bubbling = true
      yield if block_given?
    ensure
      schema.disable_error_bubbling = original_error_bubbling
    end
  end

  def error_bubbling_enabled(schema)
    original_error_bubbling = schema.disable_error_bubbling
    begin
      schema.disable_error_bubbling = false
      yield if block_given?
    ensure
      schema.disable_error_bubbling = original_error_bubbling
    end
  end
end