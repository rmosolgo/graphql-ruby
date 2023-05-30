# frozen_string_literal: true
module GraphQL
  module Execution
    # Lookahead creates a uniform interface to inspect the forthcoming selections.
    #
    # It assumes that the AST it's working with is valid. (So, it's safe to use
    # during execution, but if you're using it directly, be sure to validate first.)
    #
    # A field may get access to its lookahead by adding `extras: [:lookahead]`
    # to its configuration.
    #
    # @example looking ahead in a field
    #   field :articles, [Types::Article], null: false,
    #     extras: [:lookahead]
    #
    #   # For example, imagine a faster database call
    #   # may be issued when only some fields are requested.
    #   #
    #   # Imagine that _full_ fetch must be made to satisfy `fullContent`,
    #   # we can look ahead to see if we need that field. If we do,
    #   # we make the expensive database call instead of the cheap one.
    #   def articles(lookahead:)
    #     if lookahead.selects?(:full_content)
    #       fetch_full_articles(object)
    #     else
    #       fetch_preview_articles(object)
    #     end
    #   end
    class Lookahead
      # @param query [GraphQL::Query]
      # @param ast_nodes [Array<GraphQL::Language::Nodes::Field>, Array<GraphQL::Language::Nodes::OperationDefinition>]
      # @param field [GraphQL::Schema::Field] if `ast_nodes` are fields, this is the field definition matching those nodes
      # @param root_type [Class] if `ast_nodes` are operation definition, this is the root type for that operation
      def initialize(query:, ast_nodes:, field: nil, root_type: nil, owner_type: nil)
        @ast_nodes = ast_nodes.freeze
        @field = field
        @root_type = root_type
        @query = query
        @selected_type = @field ? @field.type.unwrap : root_type
        @owner_type = owner_type
      end

      # @return [Array<GraphQL::Language::Nodes::Field>]
      attr_reader :ast_nodes

      # @return [GraphQL::Schema::Field]
      attr_reader :field

      # @return [GraphQL::Schema::Object, GraphQL::Schema::Union, GraphQL::Schema::Interface]
      attr_reader :owner_type

      # @return [Hash<Symbol, Object>]
      def arguments
        if defined?(@arguments)
          @arguments
        else
          @arguments = if @field
            @query.after_lazy(@query.arguments_for(@ast_nodes.first, @field)) do |args|
              args.is_a?(Execution::Interpreter::Arguments) ? args.keyword_arguments : args
            end
          else
            nil
          end
        end
      end

      # True if this node has a selection on `field_name`.
      # If `field_name` is a String, it is treated as a GraphQL-style (camelized)
      # field name and used verbatim. If `field_name` is a Symbol, it is
      # treated as a Ruby-style (underscored) name and camelized before comparing.
      #
      # If `arguments:` is provided, each provided key/value will be matched
      # against the arguments in the next selection. This method will return false
      # if any of the given `arguments:` are not present and matching in the next selection.
      # (But, the next selection may contain _more_ than the given arguments.)
      # @param field_name [String, Symbol]
      # @param arguments [Hash] Arguments which must match in the selection
      # @return [Boolean]
      def selects?(field_name, selected_type: @selected_type, arguments: nil)
        selection(field_name, selected_type: selected_type, arguments: arguments).selected?
      end

      # @return [Boolean] True if this lookahead represents a field that was requested
      def selected?
        true
      end

      # Like {#selects?}, but can be used for chaining.
      # It returns a null object (check with {#selected?})
      # @param field_name [String, Symbol]
      # @return [GraphQL::Execution::Lookahead]
      def selection(field_name, selected_type: @selected_type, arguments: nil)
        next_field_defn = case field_name
        when String
          @query.get_field(selected_type, field_name)
        when Symbol
          # Try to avoid the `.to_s` below, if possible
          all_fields = if selected_type.kind.fields?
            @query.warden.fields(selected_type)
          else
            # Handle unions by checking possible
            @query.warden
              .possible_types(selected_type)
              .map { |t| @query.warden.fields(t) }
              .flatten
          end

          if (match_by_orig_name = all_fields.find { |f| f.original_name == field_name })
            match_by_orig_name
          else
            # Symbol#name is only present on 3.0+
            sym_s = field_name.respond_to?(:name) ? field_name.name : field_name.to_s
            guessed_name = Schema::Member::BuildType.camelize(sym_s)
            @query.get_field(selected_type, guessed_name)
          end
        end

        if next_field_defn
          next_nodes = []
          @ast_nodes.each do |ast_node|
            ast_node.selections.each do |selection|
              find_selected_nodes(selection, next_field_defn, arguments: arguments, matches: next_nodes)
            end
          end

          if next_nodes.any?
            Lookahead.new(query: @query, ast_nodes: next_nodes, field: next_field_defn, owner_type: selected_type)
          else
            NULL_LOOKAHEAD
          end
        else
          NULL_LOOKAHEAD
        end
      end

      # Like {#selection}, but for all nodes.
      # It returns a list of Lookaheads for all Selections
      #
      # If `arguments:` is provided, each provided key/value will be matched
      # against the arguments in each selection. This method will filter the selections
      # if any of the given `arguments:` do not match the given selection.
      #
      # @example getting the name of a selection
      #   def articles(lookahead:)
      #     next_lookaheads = lookahead.selections # => [#<GraphQL::Execution::Lookahead ...>, ...]
      #     next_lookaheads.map(&:name) #=> [:full_content, :title]
      #   end
      #
      # @param arguments [Hash] Arguments which must match in the selection
      # @return [Array<GraphQL::Execution::Lookahead>]
      def selections(arguments: nil)
        subselections_by_type = {}
        subselections_on_type = subselections_by_type[@selected_type] = {}

        @ast_nodes.each do |node|
          find_selections(subselections_by_type, subselections_on_type, @selected_type, node.selections, arguments)
        end

        subselections = []

        subselections_by_type.each do |type, ast_nodes_by_response_key|
          ast_nodes_by_response_key.each do |response_key, ast_nodes|
            field_defn = @query.get_field(type, ast_nodes.first.name)
            lookahead = Lookahead.new(query: @query, ast_nodes: ast_nodes, field: field_defn, owner_type: type)
            subselections.push(lookahead)
          end
        end

        subselections
      end

      # The method name of the field.
      # It returns the method_sym of the Lookahead's field.
      #
      # @example getting the name of a selection
      #   def articles(lookahead:)
      #     article.selection(:full_content).name # => :full_content
      #     # ...
      #   end
      #
      # @return [Symbol]
      def name
        @field && @field.original_name
      end

      def inspect
        "#<GraphQL::Execution::Lookahead #{@field ? "@field=#{@field.path.inspect}": "@root_type=#{@root_type}"} @ast_nodes.size=#{@ast_nodes.size}>"
      end

      # This is returned for {Lookahead#selection} when a non-existent field is passed
      class NullLookahead < Lookahead
        # No inputs required here.
        def initialize
        end

        def selected?
          false
        end

        def selects?(*)
          false
        end

        def selection(*)
          NULL_LOOKAHEAD
        end

        def selections(*)
          []
        end

        def inspect
          "#<GraphQL::Execution::Lookahead::NullLookahead>"
        end
      end

      # A singleton, so that misses don't come with overhead.
      NULL_LOOKAHEAD = NullLookahead.new

      private

      def skipped_by_directive?(ast_selection)
        ast_selection.directives.each do |directive|
          dir_defn = @query.schema.directives.fetch(directive.name)
          directive_class = dir_defn
          if directive_class
            dir_args = @query.arguments_for(directive, dir_defn)
            return true unless directive_class.static_include?(dir_args, @query.context)
          end
        end
        false
      end

      def find_selections(subselections_by_type, selections_on_type, selected_type, ast_selections, arguments)
        ast_selections.each do |ast_selection|
          next if skipped_by_directive?(ast_selection)

          case ast_selection
          when GraphQL::Language::Nodes::Field
            response_key = ast_selection.alias || ast_selection.name
            if selections_on_type.key?(response_key)
              selections_on_type[response_key] << ast_selection
            elsif arguments.nil? || arguments.empty?
              selections_on_type[response_key] = [ast_selection]
            else
              field_defn = @query.get_field(selected_type, ast_selection.name)
              if arguments_match?(arguments, field_defn, ast_selection)
                selections_on_type[response_key] = [ast_selection]
              end
            end
          when GraphQL::Language::Nodes::InlineFragment
            on_type = selected_type
            subselections_on_type = selections_on_type
            if (t = ast_selection.type)
              # Assuming this is valid, that `t` will be found.
              on_type = @query.get_type(t.name)
              subselections_on_type = subselections_by_type[on_type] ||= {}
            end
            find_selections(subselections_by_type, subselections_on_type, on_type, ast_selection.selections, arguments)
          when GraphQL::Language::Nodes::FragmentSpread
            frag_defn = @query.fragments[ast_selection.name] || raise("Invariant: Can't look ahead to nonexistent fragment #{ast_selection.name} (found: #{@query.fragments.keys})")
            # Again, assuming a valid AST
            on_type = @query.get_type(frag_defn.type.name)
            subselections_on_type = subselections_by_type[on_type] ||= {}
            find_selections(subselections_by_type, subselections_on_type, on_type, frag_defn.selections, arguments)
          else
            raise "Invariant: Unexpected selection type: #{ast_selection.class}"
          end
        end
      end

      # If a selection on `node` matches `field_name` (which is backed by `field_defn`)
      # and matches the `arguments:` constraints, then add that node to `matches`
      def find_selected_nodes(node, field_defn, arguments:, matches:)
        return if skipped_by_directive?(node)
        case node
        when GraphQL::Language::Nodes::Field
          if node.name == field_defn.graphql_name
            if arguments.nil? || arguments.empty?
              # No constraint applied
              matches << node
            elsif arguments_match?(arguments, field_defn, node)
              matches << node
            end
          end
        when GraphQL::Language::Nodes::InlineFragment
          node.selections.each { |s| find_selected_nodes(s, field_defn, arguments: arguments, matches: matches) }
        when GraphQL::Language::Nodes::FragmentSpread
          frag_defn = @query.fragments[node.name] || raise("Invariant: Can't look ahead to nonexistent fragment #{node.name} (found: #{@query.fragments.keys})")
          frag_defn.selections.each { |s| find_selected_nodes(s, field_defn, arguments: arguments, matches: matches) }
        else
          raise "Unexpected selection comparison on #{node.class.name} (#{node})"
        end
      end

      def arguments_match?(arguments, field_defn, field_node)
        query_kwargs = @query.arguments_for(field_node, field_defn)
        arguments.all? do |arg_name, arg_value|
          arg_name_sym = if arg_name.is_a?(String)
            Schema::Member::BuildType.underscore(arg_name).to_sym
          else
            arg_name
          end

          # Make sure the constraint is present with a matching value
          query_kwargs.key?(arg_name_sym) && query_kwargs[arg_name_sym] == arg_value
        end
      end
    end
  end
end
