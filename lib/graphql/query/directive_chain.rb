# TODO: directives on fragments: http://facebook.github.io/graphql/#sec-Fragment-Directives
class GraphQL::Query::DirectiveChain
  DIRECTIVE_ON = {
    GraphQL::Language::Nodes::Field =>          GraphQL::Directive::FIELD,
    GraphQL::Language::Nodes::InlineFragment => GraphQL::Directive::INLINE_FRAGMENT,
    GraphQL::Language::Nodes::FragmentSpread => GraphQL::Directive::FRAGMENT_SPREAD,
  }

  attr_reader :result

  def initialize(ast_node, query, &block)
    directives = query.schema.directives
    on_what = DIRECTIVE_ON[ast_node.class]
    ast_directives = ast_node.directives

    if contains_skip?(ast_directives)
      ast_directives = ast_directives.reject { |ast_directive| ast_directive.name == 'include' }
    end

    applicable_directives = ast_directives
      .map { |ast_directive| [ast_directive, directives[ast_directive.name]] }
      .select { |directive_pair| directive_pair.last.locations.include?(on_what) }

    if applicable_directives.none?
      @result = block.call
    else
      applicable_directives.map do |(ast_directive, directive)|
        args = GraphQL::Query::LiteralInput.from_arguments(ast_directive.arguments, directive.arguments, query.variables)
        @result = directive.resolve(args, block)
      end
      @result ||= {}
    end
  end

  private
  def contains_skip?(directives)
    directives.any? { |directive| directive.name == 'skip' }
  end
end
