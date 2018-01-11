# frozen_string_literal: true
begin
  require 'parser/current'
rescue LoadError
  raise LoadError, "GraphQL::Upgrader requires the 'parser' gem, please install it and/or add it to your Gemfile"
end

module GraphQL
  module Upgrader
    GRAPHQL_TYPES = '(Object|InputObject|Interface|Enum|Scalar|Union)'

    class Transform
      # @param input_text [String] Untransformed GraphQL-Ruby code
      # @param rewrite_options [Hash] Used during rewrite
      # @return [String] The input text, with a transformation applied if necessary
      def apply(input_text)
        raise NotImplementedError, "Return transformed text here"
      end

      # Recursively transform a `.define`-DSL-based type expression into a class-ready expression, for example:
      #
      # - `types[X]` -> `[X]`
      # - `Int` -> `Integer`
      # - `X!` -> `X`
      #
      # Notice that `!` is removed entirely, because it doesn't exist in the class API.
      #
      # @param type_expr [String] A `.define`-ready expression of a return type or input type
      # @return [String] A class-ready expression of the same type`
      def normalize_type_expression(type_expr, preserve_bang: false)
        case type_expr
        when /\A!/
          # Handle the bang, normalize the inside
          "#{preserve_bang ? "!" : ""}#{normalize_type_expression(type_expr[1..-1], preserve_bang: preserve_bang)}"
        when /\Atypes\[.*\]\Z/
          # Unwrap the brackets, normalize, then re-wrap
          "[#{normalize_type_expression(type_expr[6..-2], preserve_bang: preserve_bang)}]"
        when /\Atypes\./
          # Remove the prefix
          normalize_type_expression(type_expr[6..-1], preserve_bang: preserve_bang)
        when /\A->/
          # Remove the proc wrapper, don't re-apply it
          # because stabby is not supported in class-based definition
          # (and shouldn't ever be necessary)
          unwrapped = type_expr
            .sub(/\A->\s?\{\s*/, "")
            .sub(/\s*\}/, "")
          normalize_type_expression(unwrapped, preserve_bang: preserve_bang)
        when "Int"
          "Integer"
        else
          type_expr
        end
      end
    end

    # Turns `{X} = GraphQL::{Y}Type.define do` into `class {X} < Types::Base{Y}`.
    class TypeDefineToClassTransform < Transform
      # @param base_class_pattern [String] Replacement pattern for the base class name. Use this if your base classes have nonstandard names.
      def initialize(base_class_pattern: "Types::Base\\2")
        @find_pattern = /([a-zA-Z_0-9:]*) = GraphQL::#{GRAPHQL_TYPES}Type\.define do/
        @replace_pattern = "class \\1 < #{base_class_pattern}"
      end

      def apply(input_text)
        input_text.sub(@find_pattern, @replace_pattern)
      end
    end

    # Remove `name "Something"` if it is redundant with the class name.
    # Or, if it is not redundant, move it to `graphql_name "Something"`.
    class NameTransform < Transform
      def apply(transformable)
        if (matches = transformable.match(/class (?<type_name>[a-zA-Z_0-9:]*) </))
          type_name = matches[:type_name]
          # Get the name without any prefixes or suffixes
          type_name_without_the_type_part = type_name.split('::').last.gsub(/Type$/, '')
          # Find an overridden name value
          if matches = transformable.match(/ name ('|")(?<overridden_name>.*)('|")/)
            name = matches[:overridden_name]
            if type_name_without_the_type_part != name
              # If the overridden name is still required, use `graphql_name` for it
              transformable = transformable.sub(/ name (.*)/, ' graphql_name \1')
            else
              # Otherwise, remove it altogether
              transformable = transformable.sub(/\s+name ('|").*('|")/, '')
            end
          end
        end

        transformable
      end
    end

    # Remove newlines -- normalize the text for processing
    class RemoveNewlinesTransform
      def apply(input_text)
        input_text.gsub(/(?<field>(?:field|connection|argument).*?,)\n(\s*)(?<next_line>(:?"|field)(.*))/) do
          field = $~[:field].chomp
          next_line = $~[:next_line]

          "#{field} #{next_line}"
        end
      end
    end

    # Move `type X` to be the second positional argument to `field ...`
    class PositionalTypeArgTransform < Transform
      def apply(input_text)
        input_text.gsub(
          /(?<field>(?:field|connection|argument) :(?:[a-zA-Z_0-9]*)) do(?<block_contents>.*?)[ ]*type (?<return_type>.*?)\n/m
        ) do
          field = $~[:field]
          block_contents = $~[:block_contents]
          return_type = normalize_type_expression($~[:return_type], preserve_bang: true)

          "#{field}, #{return_type} do#{block_contents}"
        end
      end
    end

    # Find a configuration in the block and move it to a kwarg,
    # for example
    # ```
    # do
    #   property :thing
    # end
    # ```
    # becomes:
    # ```
    # property: thing
    # ```
    class ConfigurationToKwargTransform < Transform
      def initialize(kwarg:)
        @kwarg = kwarg
      end

      def apply(input_text)
        input_text.gsub(
          /(?<field>(?:field|connection|argument).*) do(?<block_contents>.*?)[ ]*#{@kwarg} (?<kwarg_value>.*?)\n/m
        ) do
          field = $~[:field]
          block_contents = $~[:block_contents]
          kwarg_value = $~[:kwarg_value]

          "#{field}, #{@kwarg}: #{kwarg_value} do#{block_contents}"
        end
      end
    end

    # Transform `property:` kwarg to `method:` kwarg
    class PropertyToMethodTransform < Transform
      def apply(input_text)
        input_text.gsub /property:/, 'method:'
      end
    end

    # Take camelized field names and convert them to underscore case.
    # (They'll be automatically camelized later.)
    class UnderscoreizeFieldNameTransform < Transform
      def apply(input_text)
        input_text.sub /(?<field_type>input_field|field|connection|argument) :(?<name>[a-zA-Z_0-9_]*)/ do
          field_type = $~[:field_type]
          camelized_name = $~[:name]
          underscored_name = underscorize(camelized_name)
          "#{field_type} :#{underscored_name}"
        end
      end

      def underscorize(str)
        str
          .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2') # URLDecoder -> URL_Decoder
          .gsub(/([a-z\d])([A-Z])/,'\1_\2')     # someThing -> some_Thing
          .downcase
      end
    end

    class ResolveProcToMethodTransform < Transform
      def apply(input_text)
        if input_text =~ /resolve ->/
          # - Find the proc literal
          # - Get the three argument names (obj, arg, ctx)
          # - Get the proc body
          # - Find and replace:
          #  - The ctx argument becomes `@context`
          #  - The obj argument becomes `@object`
          # - Args is trickier:
          #   - If it's not used, remove it
          #   - If it's used, abandon ship and make it `**args`
          #   - (It would be nice to correctly become Ruby kwargs, but that might be too hard)
          #   - Add a `# TODO` comment to the method source?
          # - Rebuild the method:
          #   - use the field name as the method name
          #   - handle args as described above
          #   - put the modified proc body as the method body

          input_text.match(/(?<field_type>input_field|field|connection|argument) :(?<name>[a-zA-Z_0-9_]*)/)
          field_name = $~[:name]
          field_ast = Parser::CurrentRuby.parse(input_text)
          processor = ResolveProcProcessor.new
          processor.process(field_ast)
          proc_body = input_text[processor.proc_start..processor.proc_end]
          obj_arg_name, args_arg_name, ctx_arg_name = processor.proc_arg_names
          # This is not good, it will hit false positives
          # Should use AST to make this substitution
          proc_body.gsub!(/([^\w:]|^)#{obj_arg_name}([^\w]|$)/, '\1@object\2')
          proc_body.gsub!(/([^\w:]|^)#{ctx_arg_name}([^\w]|$)/, '\1@context\2')

          indent = " " * processor.resolve_indent
          prev_body_indent = "#{indent}  "
          next_body_indent = indent
          method_def_indent = indent[2..-1]
          # Turn the proc body into a method body
          lines = proc_body.split("\n").map do |line|
            line = line.sub(prev_body_indent, "")
            "#{next_body_indent}#{line}".rstrip
          end
          # Add `def... end`
          method_def = if input_text.include?("argument ")
            # This field has arguments
            "def #{field_name}(**#{args_arg_name})"
          else
            # No field arguments, so, no method arguments
            "def #{field_name}"
          end
          lines.unshift("\n#{method_def_indent}#{method_def}")
          lines << "#{method_def_indent}end\n"
          method_body = lines.join("\n")
          # Replace the resolve proc with the method
          input_text[processor.resolve_start..processor.resolve_end] = ""
          # The replacement above might have left some preceeding whitespace,
          # so remove it by deleting all whitespace chars before `resolve`:
          preceeding_whitespace = processor.resolve_start - 1
          while input_text[preceeding_whitespace] == " " && preceeding_whitespace > 0
            input_text[preceeding_whitespace] = ""
            preceeding_whitespace -= 1
          end
          input_text += method_body
          input_text
        else
          # No resolve proc
          input_text
        end
      end


      class ResolveProcProcessor < Parser::AST::Processor
        attr_reader :proc_start, :proc_end, :proc_arg_names, :resolve_start, :resolve_end, :resolve_indent
        def initialize
          @proc_arg_names = nil
          @resolve_start = nil
          @resolve_end = nil
          @resolve_indent = nil
          @proc_start = nil
          @proc_end = nil
        end

        def on_send(node)
          receiver, method_name, _args = *node
          if method_name == :resolve && receiver.nil?
            source_exp = node.loc.expression
            @resolve_start = source_exp.begin.begin_pos
            @resolve_end = source_exp.end.end_pos
            @resolve_indent = source_exp.column
          end
          super(node)
        end

        def on_block(node)
          send_node, args_node, body_node = node.children
          _receiver, method_name, _send_args_node = *send_node
          if method_name == :lambda
            source_exp = body_node.loc.expression
            @proc_arg_names = args_node.children.map { |arg_node| arg_node.children[0].to_s }
            @proc_start = source_exp.begin.begin_pos
            @proc_end = source_exp.end.end_pos
          end
          super(node)
        end
      end
    end

    # Transform `interfaces [A, B, C]` to `implements A\nimplements B\nimplements C\n`
    class InterfacesToImplementsTransform < Transform
      def apply(input_text)
        input_text.gsub(
          /(?<indent>\s*)(?:interfaces) \[\s*(?<interfaces>(?:[a-zA-Z_0-9:\.,\s]+))\]/m
        ) do
          indent = $~[:indent]
          interfaces = $~[:interfaces].split(',').map(&:strip).reject(&:empty?)
          interfaces.map do |interface|
            "#{indent}implements #{interface}"
          end.join
        end
      end
    end

    class UpdateMethodSignatureTransform < Transform
      def apply(input_text)
        input_text.scan(/(?:input_field|field|connection|argument) .*$/).each do |field|
          matches = /(?<field_type>input_field|field|connection|argument) :(?<name>[a-zA-Z_0-9_]*)?, (?<return_type>[^,]*)(?<remainder>.*)/.match(field)
          if matches
            name = matches[:name]
            return_type = matches[:return_type]
            remainder = matches[:remainder]
            field_type = matches[:field_type]

            # This is a small bug in the regex. Ideally the `do` part would only be in the remainder.
            with_block = remainder.gsub!(/\ do$/, '') || return_type.gsub!(/\ do$/, '')

            remainder.gsub! /,$/, ''
            remainder.gsub! /^,/, ''
            remainder.chomp!

            has_bang = !(return_type.gsub! '!', '')
            return_type = normalize_type_expression(return_type)
            return_type = return_type.gsub ',', ''

            input_text.sub!(field) do
              is_argument = ['argument', 'input_field'].include?(field_type)
              f = "#{is_argument ? 'argument' : 'field'} :#{name}, #{return_type}"

              unless remainder.empty?
                f += ',' + remainder
              end

              if is_argument
                if has_bang
                  f += ', required: false'
                else
                  f += ', required: true'
                end
              else
                if has_bang
                  f += ', null: true'
                else
                  f += ', null: false'
                end
              end

              if field_type == 'connection'
                f += ', connection: true'
              end

              if with_block
                f += ' do'
              end

              f
            end
          end
        end

        input_text
      end
    end

    class RemoveEmptyBlocksTransform < Transform
      def apply(input_text)
        input_text.gsub(/\s*do\s*end/m, "")
      end
    end

    # Remove redundant newlines, which may have trailing spaces
    # Remove double newline after `do`
    class RemoveExcessWhitespaceTransform < Transform
      def apply(input_text)
        input_text
          .gsub(/\n{3,}/m, "\n")
          .gsub(/do\n\n/m, "do\n")
      end
    end

    class Member
      def initialize(member, type_transforms: DEFAULT_TYPE_TRANSFORMS, field_transforms: DEFAULT_FIELD_TRANSFORMS, clean_up_transforms: DEFAULT_CLEAN_UP_TRANSFORMS)
        @member = member
        @type_transforms = type_transforms
        @field_transforms = field_transforms
        @clean_up_transforms = clean_up_transforms
      end

      DEFAULT_TYPE_TRANSFORMS = [
        TypeDefineToClassTransform,
        NameTransform,
        InterfacesToImplementsTransform,
      ]

      DEFAULT_FIELD_TRANSFORMS = [
        RemoveNewlinesTransform,
        PositionalTypeArgTransform,
        ConfigurationToKwargTransform.new(kwarg: "property"),
        ConfigurationToKwargTransform.new(kwarg: "description"),
        PropertyToMethodTransform,
        UnderscoreizeFieldNameTransform,
        ResolveProcToMethodTransform,
        UpdateMethodSignatureTransform,
      ]

      DEFAULT_CLEAN_UP_TRANSFORMS = [
        RemoveExcessWhitespaceTransform,
        RemoveEmptyBlocksTransform,
      ]

      def upgrade
        # Transforms on type defn code:
        type_source = apply_transforms(@member.dup, @type_transforms)
        # Transforms on each field:
        field_sources = find_fields(type_source)
        field_sources.each do |field_source|
          transformed_field_source = apply_transforms(field_source.dup, @field_transforms)
          # Replace the original source code with the transformed source code:
          type_source = type_source.gsub(field_source, transformed_field_source)
        end
        # Clean-up:
        type_source = apply_transforms(type_source, @clean_up_transforms)
        # Return the transformed source:
        type_source
      end

      def upgradeable?
        return false if @member.include? '< GraphQL::Schema::'
        return false if @member =~ /< Types::Base#{GRAPHQL_TYPES}/

        true
      end

      private

      def apply_transforms(source_code, transforms, idx: 0)
        next_transform = transforms[idx]
        case next_transform
        when nil
          # We got to the end of the list
          source_code
        when Class
          # Apply a class
          next_source_code = next_transform.new.apply(source_code)
          apply_transforms(next_source_code, transforms, idx: idx + 1)
        else
          # Apply an already-initialized object which responds to `apply`
          next_source_code = next_transform.apply(source_code)
          apply_transforms(next_source_code, transforms, idx: idx + 1)
        end
      end

      # Parse the type, find calls to `field` and `connection`
      # Return strings containing those calls
      def find_fields(type_source)
        type_ast = Parser::CurrentRuby.parse(type_source)
        finder = FieldFinder.new
        finder.process(type_ast)
        field_sources = []
        # For each of the locations we found, extract the text for that definition.
        # The text will be transformed independently,
        # then the transformed text will replace the original text.
        finder.locations.each do |name, (starting_idx, ending_idx)|
          field_source = type_source[starting_idx..ending_idx]
          field_sources << field_source
        end
        # Here's a crazy thing: the transformation is pure,
        # so definitions like `argument :id, types.ID` can be transformed once
        # then replaced everywhere. So:
        # - make a unique array here
        # - use `gsub` after performing the transformation.
        field_sources.uniq!
        field_sources
      end

      class FieldFinder < Parser::AST::Processor
        # These methods are definition DSLs which may accept a block,
        # each of these definitions is passed for transformation in its own right
        DEFINITION_METHODS = [:field, :connection, :input_field, :argument]
        attr_reader :locations

        def initialize
          # Pairs of `{ name => [start, end] }`,
          # since we know fields are unique by name.
          @locations = {}
        end

        # @param send_node [node] The node which might be a `field` call, etc
        # @param source_node [node] The node whose source defines the bounds of the definition (eg, the surrounding block)
        def add_location(send_node:,source_node:)
          receiver_node, method_name, *arg_nodes = *send_node
          # Implicit self and one of the recognized methods
          if receiver_node.nil? && DEFINITION_METHODS.include?(method_name)
            name = arg_nodes[0]
            # This field may have already been added because
            # we find `(block ...)` nodes _before_ we find `(send ...)` nodes.
            if @locations[name].nil?
              starting_idx = source_node.loc.expression.begin.begin_pos
              ending_idx = source_node.loc.expression.end.end_pos
              @locations[name] = [starting_idx, ending_idx]
            end
          end
        end

        def on_block(node)
          send_node, _args_node, _body_node = *node
          add_location(send_node: send_node, source_node: node)
          super(node)
        end

        def on_send(node)
          add_location(send_node: node, source_node: node)
          super(node)
        end
      end
    end
  end
end
