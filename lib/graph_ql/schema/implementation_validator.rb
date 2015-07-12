# A helper to ensure `object` implements the concept `as`
class GraphQL::Schema::ImplementationValidator
  attr_reader :object, :errors, :implementation_as
  def initialize(object, as:, errors:)
    @object = object
    @implementation_as = as
    @errors = errors
  end

  def must_respond_to(method_name, args: [], as: nil)
    if !object.respond_to?(method_name)
      local_as = as || implementation_as
      errors << "#{object.to_s} must respond to ##{method_name}(#{args.join(", ")}) to be a #{local_as}"
    end
  end
end
