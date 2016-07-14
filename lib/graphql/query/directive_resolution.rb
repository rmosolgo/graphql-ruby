module GraphQL
  class Query
    module DirectiveResolution
      def self.include_node?(irep_node, query)
        irep_node.directives.each do |directive_node|
          directive_defn = directive_node.definition
          args = query.arguments_for(directive_node)
          if !directive_defn.include?(args)
            return false
          end
        end
        true
      end
    end
  end
end
