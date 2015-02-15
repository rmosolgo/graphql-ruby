class GraphQL::Introspection::RootCallArgumentNode < GraphQL::Node
  field :name
  field :type

  def method_missing(method_name)
    target_value = @target[method_name]
    if target_value.present?
      target_value.to_s
    else
      super
    end
  end
end