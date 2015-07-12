# A helper to ensure `object` implements the concept `as`
class GraphQL::Schema::ImplementationValidator
  attr_reader :object, :as, :errors
  def initialize(object, as:, errors:)
    @object = object
    @as = as
    @errors = errors
  end

  def must_respond_to(method_name, args: [])
    if !object.respond_to?(method_name)
      errors << "#{object.to_s} must respond to ##{method_name}(#{args.join(", ")}) to be a #{as}"
    end
  end
end
