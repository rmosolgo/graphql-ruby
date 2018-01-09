# frozen_string_literal: true
require 'parser/current'
require 'forwardable'

module GraphQL
  module Upgrader
    class Member
      def initialize(member)
        @member = member
      end

      def upgrade
        transformable = member.dup

        ast = Parser::CurrentRuby.parse(transformable)
        buffer = Parser::Source::Buffer.new('(example)')
        buffer.source = transformable
        rewriter = TransformField.new
        rewriter.rewrite(buffer, ast)
      end

      attr_reader :member

      private
        GRAPHQL_TYPES = 'Object|InputObject|Interface|Enum|Scalar|Union'

        class TransformField < Parser::AST::Processor
          extend Forwardable
          include AST::Sexp # import name `s`

          def rewrite(source_buffer, ast)
            @source_buffer = source_buffer
            @source_rewriter = Parser::Source::Rewriter.new(source_buffer)

            process(ast)

            @source_rewriter.process
          end

          def_delegators :@source_rewriter, :remove, :replace, :insert_before_multi, :insert_after_multi

          def on_casgn(node)
            # Valid definition likes:
            # s(:casgn,
            #   s(:const, nil, :Types), :AutherType,
            #   s(:block,
            #     s(:send,
            #       s(:const,
            #         s(:const, nil, :GraphQL), :ObjectType), :define),
            #     s(:args),
            #     s(:block,
            #     ......
            _mod, class_name, definition = node.children
            return if definition.type != :block

            base_type, args, *body = definition.children

            defined_gql = GRAPHQL_TYPES.split('|').any? do |type|
              base_type == s(:send,
                s(:const,
                  s(:const, nil, :GraphQL), :"#{type}Type"), :define)
            end

            return unless defined_gql && args == s(:args)

            do_loc = definition.loc.begin
            do_loc = Parser::Source::Range.new(@source_buffer, do_loc.begin_pos - 1, do_loc.end_pos)
            remove(do_loc)

            body.each do |stmt|
              next unless stmt
              if stmt.type == :send && stmt.children[0].nil?
                method_name = stmt.children[1]
                if method_name == :name
                  name = stmt.children[2].loc.expression.source[1...-1]

                  if class_name.to_s =~ /^#{name}Type/
                    remove(stmt.loc.expression)
                  else
                    replace(stmt.loc.selector, 'graphql_name')
                  end
                end
              else
                process(stmt)
              end
            end

            base_type.loc.expression.source =~ /(#{GRAPHQL_TYPES})Type.define/
            base_class = $~[1]

            insert_before_multi(node.loc.expression, 'class ')

            asgn_range = Parser::Source::Range.new(@source_buffer, node.loc.name.end_pos, base_type.loc.expression.begin_pos)
            replace(asgn_range, ' < ')

            replace(base_type.loc.expression, "Types::Base#{base_class}")
          end

          def on_block(node)
            call, _call_args, body = node.children

            return unless call.type == :send && call.children[0].nil? && [:field, :connection].include?(call.children[1])

            if body
              if body.type == :begin
                body = body.children
              else
                body = [body]
              end
            else
              body = []
            end

            declare_options = {}
            declare_args = []
            body.each do |child|
              if child.is_a?(Parser::AST::Node) && child.type == :send && [:type, :description, :resolve].include?(child.children[1])
                declare_options[child.children[1]] = child.children[2]
                range = child.loc.expression
                remove(range)
              else
                process(child)
              end
            end

            process_field(call, declare_args, declare_options)
          end

          def process_field(field_node, declare_args = [], declare_options = {})
            is_connection = false
            if field_node.children[1] == :connection
              is_connection = true
              replace(field_node.loc.selector, 'field')
            end

            if declare_options.has_key?(:type)
              type = declare_options.delete(:type).loc.expression.source
              type, nullable = convert_type(type)
              declare_args << type
            else
              declare_args << nil # placeholder
            end
            if declare_options.has_key?(:description)
              declare_args << declare_options.delete(:description).loc.expression.source
            end

            args = field_node.children[2..-1]

            # Add before hash parameters
            non_hash_params = args[1..-1].select{|arg| arg.type != :hash}

            if non_hash_params.length > 0
              type_param = non_hash_params.first
              type, nullable = convert_type(type_param.loc.expression.source)
              replace(type_param.loc.expression, type)
            end

            add_pos = args.select{|arg| arg.type != :hash}.last.loc.expression

            add_args = declare_args[non_hash_params.length..-1] || []
            add_args.each do |arg|
              insert_after_multi(add_pos, ", #{arg}")
            end

            insert_after_multi(add_pos, ", null: #{nullable}")
            if is_connection
              insert_after_multi(add_pos, ", connection: true")
            end
            declare_options.to_a.each do |key, value|
              value_source = value.loc.expression.source
              insert_after_multi(args.last.loc.expression, ", #{key}: #{value_source}")
            end

            last_arg = args.last

            if last_arg && last_arg.type == :hash
              hash_args = last_arg.children
              hash_args.each do |pair|
                next if pair.type != :pair

                key = pair.children.first
                if key.type == :sym && key.children.first == :property
                  replace(key.loc.expression, 'method')
                end
              end
            end
          end

          def on_send(node)
            method_name = node.children[1]
            if [:argument, :input_field].include?(method_name)
              # Replace input_field to argument
              replace(node.loc.selector, 'argument')

              arg_type = node.children[3]
              type, nullable = convert_type(arg_type.loc.expression.source)

              # Convert types.X, !types.X to X
              replace(arg_type.loc.expression, type)
              # Add required property
              insert_after_multi(node.children.last.loc.expression, ", required: #{!nullable}")
            elsif method_name == :interfaces
              interfaces = node.children[2]
              return if interfaces.type != :array
              interfaces.children.each do |interface|
                indent = get_indent_chars(node.loc.expression)
                insert_after_multi(interfaces.loc.expression, "\n#{indent}implements #{interface.loc.expression.source}")
              end
              remove(node.loc.expression)
            elsif [:field, :connection].include?(method_name)
              process_field(node)
            end
          end

          def get_indent_chars(loc)
            if @source_buffer.slice(0...loc.begin_pos) =~ /[ \t]*\Z/
              $~[0]
            else
              ''
            end
          end

          def convert_type(type)
            nullable = !type.include?('!')
            type.gsub!(/!/, '')
            type.gsub!(/types\./, '')
            type.gsub!(/types\[(.*)\]/, '[\1]')
            [type, nullable]
          end
        end
    end
  end
end
