class GraphQL::DirectiveChain
  attr_reader :result
  def initialize(on_what, operation_resolver, ast_directives, &block)
    directives = operation_resolver.query.schema.directives
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
