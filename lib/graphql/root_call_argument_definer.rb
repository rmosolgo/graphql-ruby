# Enables the {RootCall.argument} API, used internall by GraphQL
class GraphQL::RootCallArgumentDefiner
  ARGUMENT_TYPES = [:string, :object, :number]

  attr_reader :arguments

  def initialize(call_class)
    @call_class = call_class
    @arguments = []
  end

  def none
    @arguments = []
  end

  ARGUMENT_TYPES.each do |arg_type|
    define_method arg_type do |name, any_number: false|
      @arguments << GraphQL::RootCallArgument.new(type: arg_type.to_s, name: name.to_s, any_number: any_number)
    end
  end
end