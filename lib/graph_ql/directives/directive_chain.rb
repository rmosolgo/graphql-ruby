class GraphQL::DirectiveChain
  DIRECTIVE_ON = {
    GraphQL::Nodes::Field =>          GraphQL::Directive::ON_FIELD,
    GraphQL::Nodes::InlineFragment => GraphQL::Directive::ON_FRAGMENT,
    GraphQL::Nodes::FragmentSpread => GraphQL::Directive::ON_FRAGMENT
  }

  GET_DIRECTIVES = {
    GraphQL::Nodes::Field =>          proc { |n, _f| n.directives },
    GraphQL::Nodes::InlineFragment => proc { |n, _f| n.directives },
    GraphQL::Nodes::FragmentSpread => proc { |n, f| n.directives + f[n.name].directives }, # get directives from definition too
  }

  attr_reader :result
  def initialize(ast_node, operation_resolver, &block)
    directives = operation_resolver.query.schema.directives
    on_what = DIRECTIVE_ON[ast_node.class]
    ast_directives = GET_DIRECTIVES[ast_node.class].call(ast_node, operation_resolver.query.fragments)
    applicable_directives = ast_directives
                            .map { |ast_directive| [ast_directive, directives[ast_directive.name]] }
                            .select { |directive_pair| directive_pair.last.on.include?(on_what) }

    if applicable_directives.none?
      @result = block.call
    else
      applicable_directives.map do |(ast_directive, directive)|
        args = GraphQL::Query::Arguments.new(ast_directive.arguments, operation_resolver.variables).to_h
        @result = directive.resolve(args, block)
      end
      @result ||= {}
    end
  end
end
