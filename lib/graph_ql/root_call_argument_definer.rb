# Enables the {RootCall.argument} API, used internall by GraphQL
class GraphQL::RootCallArgumentDefiner
  ARGUMENT_TYPES = [:string, :object, :number]

  def initialize(owner)
    @owner = owner
  end

  def none
  end

  ARGUMENT_TYPES.each do |arg_type|
    define_method arg_type do |name, any_number: false|
      @owner.add_argument(GraphQL::RootCallArgument.new(type: arg_type.to_s, name: name.to_s, any_number: any_number))
    end
  end
end