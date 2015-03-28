# This root call takes different arguments.
class GraphQL::RootCallArgumentError < GraphQL::Error
  def initialize(declaration, actual)
    super("Wrong type for #{declaration.name}: expected a #{declaration.type} but got #{actual}")
  end
end