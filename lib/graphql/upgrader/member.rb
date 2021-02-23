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
      # @return [String] The input text, with a transformation applied if necessary
      def apply(input_text)
        raise GraphQL::RequiredImplementationMissingError, "Return transformed text here"
      end

      # Recursively transform a `.define`-DSL-based type expression into a class-ready expression, for example:
      #
      # - `types[X]` -> `[X, null: true]`
      # - `types[X.to_non_null_type]` -> `[X]`
      # - `Int` -> `Integer`
      # - `X!` -> `X`
      #
      # Notice that `!` is removed sometimes, because it doesn't exist in the class API.
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
          inner_type = type_expr[6..-2]
          if inner_type.start_with?("!")
            nullable = false
            inner_type = inner_type[1..-1]
          elsif inner_type.end_with?(".to_non_null_type")
            nullable = false
            inner_type = inner_type[0...-17]
          else
            nullable = true
          end

          "[#{normalize_type_expression(inner_type, preserve_bang: preserve_bang)}#{nullable ? ", null: true" : ""}]"
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

      def underscorize(str)
        str
          .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2') # URLDecoder -> URL_Decoder
          .gsub(/([a-z\d])([A-Z])/,'\1_\2')     # someThing -> some_Thing
          .downcase
      end

      def apply_processor(input_text, processor)
        ruby_ast = Parser::CurrentRuby.parse(input_text)
        processor.process(ruby_ast)
        processor
      rescue Parser::SyntaxError
        puts "Error text:"
        puts input_text
        raise
      end

      def reindent_lines(input_text, from_indent:, to_indent:)
        prev_indent = " " * from_indent
        next_indent = " " * to_indent
        # For each line, remove the previous indent, then add the new indent
        lines = input_text.split("\n").map do |line|
          line = line.sub(prev_indent, "")
          "#{next_indent}#{line}".rstrip
        end
        lines.join("\n")
      end

      # Remove trailing whitespace
      def trim_lines(input_text)
        input_text.gsub(/ +$/, "")
      end
    end

    # Turns `{X} = GraphQL::{Y}Type.define do` into `class {X} < Types::Base{Y}`.
    class TypeDefineToClassTransform < Transform
      # @param base_class_pattern [String] Replacement pattern for the base class name. Use this if your base classes have nonstandard names.
      def initialize(base_class_pattern: "Types::Base\\3")
        @find_pattern = /( *)([a-zA-Z_0-9:]*) = GraphQL::#{GRAPHQL_TYPES}Type\.define do/
        @replace_pattern = "\\1class \\2 < #{base_class_pattern}"
        @interface_replace_pattern = "\\1module \\2\n\\1  include #{base_class_pattern}"
      end

      def apply(input_text)
        if input_text.include?("GraphQL::InterfaceType.define")
          input_text.sub(@find_pattern, @interface_replace_pattern)
        else
          input_text.sub(@find_pattern, @replace_pattern)
        end
      end
    end

    # Turns `{X} = GraphQL::Relay::Mutation.define do` into `class {X} < Mutations::BaseMutation`
    class MutationDefineToClassTransform < Transform
      # @param base_class_name [String] Replacement pattern for the base class name. Use this if your Mutation base class has a nonstandard name.
      def initialize(base_class_name: "Mutations::BaseMutation")
        @find_pattern = /([a-zA-Z_0-9:]*) = GraphQL::Relay::Mutation.define do/
        @replace_pattern = "class \\1 < #{base_class_name}"
      end

      def apply(input_text)
        input_text.gsub(@find_pattern, @replace_pattern)
      end
    end

    # Remove `name "Something"` if it is redundant with the class name.
    # Or, if it is not redundant, move it to `graphql_name "Something"`.
    class NameTransform < Transform
      def apply(transformable)
        last_type_defn = transformable
          .split("\n")
          .select { |line| line.include?("class ") || line.include?("module ")}
          .last

        if last_type_defn && (matches = last_type_defn.match(/(class|module) (?<type_name>[a-zA-Z_0-9:]*)( <|$)/))
          type_name = matches[:type_name]
          # Get the name without any prefixes or suffixes
          type_name_without_the_type_part = type_name.split('::').last.gsub(/Type$/, '')
          # Find an overridden name value
          if matches = transformable.match(/ name ('|")(?<overridden_name>.*)('|")/)
            name = matches[:overridden_name]
            if type_name_without_the_type_part != name
              # If the overridden name is still required, use `graphql_name` for it
              transformable = transformable.gsub(/ name (.*)/, ' graphql_name \1')
            else
              # Otherwise, remove it altogether
              transformable = transformable.gsub(/\s+name ('|").*('|")/, '')
            end
          end
        end

        transformable
      end
    end

    # Remove newlines -- normalize the text for processing
    class RemoveNewlinesTransform
      def apply(input_text)
        keep_looking = true
        while keep_looking do
          keep_looking = false
          # Find the `field` call (or other method), and an open paren, but not a close paren, or a comma between arguments
          input_text = input_text.gsub(/(?<field>(?:field|input_field|return_field|connection|argument)(?:\([^)]*|.*,))\n\s*(?<next_line>.+)/) do
            keep_looking = true
            field = $~[:field].chomp
            next_line = $~[:next_line]

            "#{field} #{next_line}"
          end
        end
        input_text
      end
    end

    # Remove parens from method call - normalize for processing
    class RemoveMethodParensTransform < Transform
      def apply(input_text)
        input_text.sub(
          /(field|input_field|return_field|connection|argument)\( *(.*?) *\)( *)/,
          '\1 \2\3'
        )
      end
    end

    # Move `type X` to be the second positional argument to `field ...`
    class PositionalTypeArgTransform < Transform
      def apply(input_text)
        input_text.gsub(
          /(?<field>(?:field|input_field|return_field|connection|argument) :(?:[a-zA-Z_0-9]*)) do(?<block_contents>.*?)[ ]*type (?<return_type>.*?)\n/m
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
          /(?<field>(?:field|return_field|input_field|connection|argument).*) do(?<block_contents>.*?)[ ]*#{@kwarg} (?<kwarg_value>.*?)\n/m
        ) do
          field = $~[:field]
          block_contents = $~[:block_contents]
          kwarg_value = $~[:kwarg_value].strip

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

    # Find a keyword whose value is a string or symbol,
    # and if the value is equivalent to the field name,
    # remove the keyword altogether.
    class RemoveRedundantKwargTransform < Transform
      def initialize(kwarg:)
        @kwarg = kwarg
        @finder_pattern = /(field|return_field|input_field|connection|argument) :(?<name>[a-zA-Z_0-9]*).*#{@kwarg}: ['":](?<kwarg_value>[a-zA-Z_0-9?!]+)['"]?/
      end

      def apply(input_text)
        if input_text =~ @finder_pattern
          field_name = $~[:name]
          kwarg_value = $~[:kwarg_value]
          if field_name == kwarg_value
            # It's redundant, remove it
            input_text = input_text.sub(/, #{@kwarg}: ['":]#{kwarg_value}['"]?/, "")
          end
        end
        input_text
      end
    end

    # Take camelized field names and convert them to underscore case.
    # (They'll be automatically camelized later.)
    class UnderscoreizeFieldNameTransform < Transform
      def apply(input_text)
        input_text.gsub /(?<field_type>input_field|return_field|field|connection|argument) :(?<name>[a-zA-Z_0-9_]*)/ do
          field_type = $~[:field_type]
          camelized_name = $~[:name]
          underscored_name = underscorize(camelized_name)
          "#{field_type} :#{underscored_name}"
        end
      end
    end

    class ProcToClassMethodTransform < Transform
      # @param proc_name [String] The name of the proc to be moved to `def self.#{proc_name}`
      def initialize(proc_name)
        @proc_name = proc_name
        # This will tell us whether to operate on the input or not
        @proc_check_pattern = /#{proc_name}\s?->/
      end

      def apply(input_text)
        if input_text =~ @proc_check_pattern
          processor = apply_processor(input_text, NamedProcProcessor.new(@proc_name))
          processor.proc_to_method_sections.reverse.each do |proc_to_method_section|
            proc_body = input_text[proc_to_method_section.proc_body_start..proc_to_method_section.proc_body_end]
            method_defn_indent = " " * proc_to_method_section.proc_defn_indent
            method_defn = "def self.#{@proc_name}(#{proc_to_method_section.proc_arg_names.join(", ")})\n#{method_defn_indent}  #{proc_body}\n#{method_defn_indent}end\n"
            method_defn = trim_lines(method_defn)
            # replace the proc with the new method
            input_text[proc_to_method_section.proc_defn_start..proc_to_method_section.proc_defn_end] = method_defn
          end
        end
        input_text
      end

      class NamedProcProcessor < Parser::AST::Processor
        attr_reader :proc_to_method_sections
        def initialize(proc_name)
          @proc_name_sym = proc_name.to_sym
          @proc_to_method_sections = []
        end

        class ProcToMethodSection
          attr_accessor :proc_arg_names, :proc_defn_start, :proc_defn_end, :proc_defn_indent, :proc_body_start, :proc_body_end, :inside_proc

          def initialize
            # @proc_name_sym = proc_name.to_sym
            @proc_arg_names = nil
            # Beginning of the `#{proc_name} -> {...}` call
            @proc_defn_start = nil
            # End of the last `end/}`
            @proc_defn_end = nil
            # Amount of whitespace to insert to the rewritten body
            @proc_defn_indent = nil
            # First statement of the proc
            @proc_body_start = nil
            # End of last statement in the proc
            @proc_body_end = nil
            # Used for identifying the proper block
            @inside_proc = false
          end
        end

        def on_send(node)
          receiver, method_name, _args = *node
          if method_name == @proc_name_sym && receiver.nil?
            proc_section = ProcToMethodSection.new
            source_exp = node.loc.expression
            proc_section.proc_defn_start = source_exp.begin.begin_pos
            proc_section.proc_defn_end = source_exp.end.end_pos
            proc_section.proc_defn_indent = source_exp.column
            proc_section.inside_proc = true

            @proc_to_method_sections << proc_section
          end
          res = super(node)
          @inside_proc = false
          res
        end

        def on_block(node)
          send_node, args_node, body_node = node.children
          _receiver, method_name, _send_args_node = *send_node
          if method_name == :lambda && !@proc_to_method_sections.empty? && @proc_to_method_sections[-1].inside_proc
            proc_to_method_section = @proc_to_method_sections[-1]

            source_exp = body_node.loc.expression
            proc_to_method_section.proc_arg_names = args_node.children.map { |arg_node| arg_node.children[0].to_s }
            proc_to_method_section.proc_body_start = source_exp.begin.begin_pos
            proc_to_method_section.proc_body_end = source_exp.end.end_pos
            proc_to_method_section.inside_proc = false
          end
          super(node)
        end
      end
    end

    class MutationResolveProcToMethodTransform < Transform
      # @param proc_name [String] The name of the proc to be moved to `def self.#{proc_name}`
      def initialize(proc_name: "resolve")
        @proc_name = proc_name
      end

      # TODO dedup with ResolveProcToMethodTransform
      def apply(input_text)
        if input_text =~ /GraphQL::Relay::Mutation\.define/
          named_proc_processor = apply_processor(input_text, ProcToClassMethodTransform::NamedProcProcessor.new(@proc_name))
          resolve_proc_processor = apply_processor(input_text, ResolveProcToMethodTransform::ResolveProcProcessor.new)

          named_proc_processor.proc_to_method_sections.zip(resolve_proc_processor.resolve_proc_sections).reverse.each do |pair|
            proc_to_method_section, resolve_proc_section = *pair
            proc_body = input_text[proc_to_method_section.proc_body_start..proc_to_method_section.proc_body_end]
            method_defn_indent = " " * proc_to_method_section.proc_defn_indent

            obj_arg_name, args_arg_name, ctx_arg_name = resolve_proc_section.proc_arg_names
            # This is not good, it will hit false positives
            # Should use AST to make this substitution
            if obj_arg_name != "_"
              proc_body.gsub!(/([^\w:.]|^)#{obj_arg_name}([^\w:]|$)/, '\1object\2')
            end
            if ctx_arg_name != "_"
              proc_body.gsub!(/([^\w:.]|^)#{ctx_arg_name}([^\w:]|$)/, '\1context\2')
            end

            method_defn = "def #{@proc_name}(**#{args_arg_name})\n#{method_defn_indent}  #{proc_body}\n#{method_defn_indent}end\n"
            method_defn = trim_lines(method_defn)
            # Update usage of args keys
            method_defn = method_defn.gsub(/#{args_arg_name}(?<method_begin>\.key\?\(?|\[)["':](?<arg_name>[a-zA-Z0-9_]+)["']?(?<method_end>\]|\))?/) do
              method_begin = $~[:method_begin]
              arg_name = underscorize($~[:arg_name])
              method_end = $~[:method_end]
              "#{args_arg_name}#{method_begin}:#{arg_name}#{method_end}"
            end
            # replace the proc with the new method
            input_text[proc_to_method_section.proc_defn_start..proc_to_method_section.proc_defn_end] = method_defn
          end
        end
        input_text
      end
    end

    # Find hash literals which are returned from mutation resolves,
    # and convert their keys to underscores. This catches a lot of cases but misses
    # hashes which are initialized anywhere except in the return expression.
    class UnderscorizeMutationHashTransform < Transform
      def apply(input_text)
        if input_text =~ /def resolve\(\*\*/
          processor = apply_processor(input_text, ReturnedHashLiteralProcessor.new)
          # Use reverse_each to avoid messing up positions
          processor.keys_to_upgrade.reverse_each do |key_data|
            underscored_key = underscorize(key_data[:key].to_s)
            if key_data[:operator] == ":"
              input_text[key_data[:start]...key_data[:end]] = underscored_key
            else
              input_text[key_data[:start]...key_data[:end]] = ":#{underscored_key}"
            end
          end
        end
        input_text
      end

      class ReturnedHashLiteralProcessor < Parser::AST::Processor
        attr_reader :keys_to_upgrade
        def initialize
          @keys_to_upgrade = []
        end

        def on_def(node)
          method_name, _args, body = *node
          if method_name == :resolve
            possible_returned_hashes = find_returned_hashes(body, returning: false)
            possible_returned_hashes.each do |hash_node|
              pairs = *hash_node
              pairs.each do |pair_node|
                if pair_node.type == :pair # Skip over :kwsplat
                  pair_k, _pair_v = *pair_node
                  if pair_k.type == :sym && pair_k.children[0].to_s =~ /[a-z][A-Z]/ # Does it have any camelcase boundaries?
                    source_exp = pair_k.loc.expression
                    @keys_to_upgrade << {
                      start: source_exp.begin.begin_pos,
                      end: source_exp.end.end_pos,
                      key: pair_k.children[0],
                      operator: pair_node.loc.operator.source,
                    }
                  end
                end
              end
            end
          end

        end

        private

        # Look for hash nodes, starting from `node`.
        # Return hash nodes that are valid candiates for returning from this method.
        def find_returned_hashes(node, returning:)
          if node.is_a?(Array)
            *possible_returns, last_expression = *node
            return possible_returns.map { |c| find_returned_hashes(c, returning: false) }.flatten +
              # Check the last expression of a method body
              find_returned_hashes(last_expression, returning: returning)
          end

          case node.type
          when :hash
            if returning
              [node]
            else
              # This is some random hash literal
              []
            end
          when :begin
            # Check the last expression of a method body
            find_returned_hashes(node.children, returning: true)
          when :resbody
            _condition, _assign, body = *node
            find_returned_hashes(body, returning: returning)
          when :kwbegin
            find_returned_hashes(node.children, returning: returning)
          when :rescue
            try_body, rescue_body, _ensure_body = *node
            find_returned_hashes(try_body, returning: returning) + find_returned_hashes(rescue_body, returning: returning)
          when :block
            # Check methods with blocks for possible returns
            method_call, _args, *body = *node
            if method_call.type == :send
              find_returned_hashes(body, returning: returning)
            end
          when :if
            # Check each branch of a conditional
            _condition, *branches = *node
            branches.compact.map { |b| find_returned_hashes(b, returning: returning) }.flatten
          when :return
            find_returned_hashes(node.children.first, returning: true)
          else
            []
          end
        rescue
          p "--- UnderscorizeMutationHashTransform crashed on node: ---"
          p node
          raise
        end

      end
    end

    class ResolveProcToMethodTransform < Transform
      def apply(input_text)
        if input_text =~ /resolve\(? ?->/
          # - Find the proc literal
          # - Get the three argument names (obj, arg, ctx)
          # - Get the proc body
          # - Find and replace:
          #  - The ctx argument becomes `context`
          #  - The obj argument becomes `object`
          # - Args is trickier:
          #   - If it's not used, remove it
          #   - If it's used, abandon ship and make it `**args`
          #   - Convert string args access to symbol access, since it's a Ruby **splat
          #   - Convert camelized arg names to underscored arg names
          #   - (It would be nice to correctly become Ruby kwargs, but that might be too hard)
          #   - Add a `# TODO` comment to the method source?
          # - Rebuild the method:
          #   - use the field name as the method name
          #   - handle args as described above
          #   - put the modified proc body as the method body

          input_text.match(/(?<field_type>input_field|field|connection|argument) :(?<name>[a-zA-Z_0-9_]*)/)
          field_name = $~[:name]
          processor = apply_processor(input_text, ResolveProcProcessor.new)

          processor.resolve_proc_sections.reverse.each do |resolve_proc_section|
            proc_body = input_text[resolve_proc_section.proc_start..resolve_proc_section.proc_end]
            obj_arg_name, args_arg_name, ctx_arg_name = resolve_proc_section.proc_arg_names
            # This is not good, it will hit false positives
            # Should use AST to make this substitution
            if obj_arg_name != "_"
              proc_body.gsub!(/([^\w:.]|^)#{obj_arg_name}([^\w:]|$)/, '\1object\2')
            end
            if ctx_arg_name != "_"
              proc_body.gsub!(/([^\w:.]|^)#{ctx_arg_name}([^\w:]|$)/, '\1context\2')
            end

            method_def_indent = " " * (resolve_proc_section.resolve_indent - 2)
            # Turn the proc body into a method body
            method_body = reindent_lines(proc_body, from_indent: resolve_proc_section.resolve_indent + 2, to_indent: resolve_proc_section.resolve_indent)
            # Add `def... end`
            method_def = if input_text.include?("argument ")
              # This field has arguments
              "def #{field_name}(**#{args_arg_name})"
            else
              # No field arguments, so, no method arguments
              "def #{field_name}"
            end
            # Wrap the body in def ... end
            method_body = "\n#{method_def_indent}#{method_def}\n#{method_body}\n#{method_def_indent}end\n"
            # Update Argument access to be underscore and symbols
            # Update `args[...]` and `args.key?`
            method_body = method_body.gsub(/#{args_arg_name}(?<method_begin>\.key\?\(?|\[)["':](?<arg_name>[a-zA-Z0-9_]+)["']?(?<method_end>\]|\))?/) do
              method_begin = $~[:method_begin]
              arg_name = underscorize($~[:arg_name])
              method_end = $~[:method_end]
              "#{args_arg_name}#{method_begin}:#{arg_name}#{method_end}"
            end

            # Replace the resolve proc with the method
            input_text[resolve_proc_section.resolve_start..resolve_proc_section.resolve_end] = ""
            # The replacement above might have left some preceeding whitespace,
            # so remove it by deleting all whitespace chars before `resolve`:
            preceeding_whitespace = resolve_proc_section.resolve_start - 1
            while input_text[preceeding_whitespace] == " " && preceeding_whitespace > 0
              input_text[preceeding_whitespace] = ""
              preceeding_whitespace -= 1
            end
            input_text += method_body
            input_text
          end
        end

        input_text
      end

      class ResolveProcProcessor < Parser::AST::Processor
        attr_reader :resolve_proc_sections
        def initialize
          @resolve_proc_sections = []
        end

        class ResolveProcSection
          attr_accessor :proc_start, :proc_end, :proc_arg_names, :resolve_start, :resolve_end, :resolve_indent
          def initialize
            @proc_arg_names = nil
            @resolve_start = nil
            @resolve_end = nil
            @resolve_indent = nil
            @proc_start = nil
            @proc_end = nil
          end
        end

        def on_send(node)
          receiver, method_name, _args = *node
          if method_name == :resolve && receiver.nil?
            resolve_proc_section = ResolveProcSection.new
            source_exp = node.loc.expression
            resolve_proc_section.resolve_start = source_exp.begin.begin_pos
            resolve_proc_section.resolve_end = source_exp.end.end_pos
            resolve_proc_section.resolve_indent = source_exp.column

            @resolve_proc_sections << resolve_proc_section
          end
          super(node)
        end

        def on_block(node)
          send_node, args_node, body_node = node.children
          _receiver, method_name, _send_args_node = *send_node
          # Assume that the first three-argument proc we enter is the resolve
          if (
            method_name == :lambda && args_node.children.size == 3 &&
            !@resolve_proc_sections.empty? && @resolve_proc_sections[-1].proc_arg_names.nil?
          )
            resolve_proc_section = @resolve_proc_sections[-1]
            source_exp = body_node.loc.expression
            resolve_proc_section.proc_arg_names = args_node.children.map { |arg_node| arg_node.children[0].to_s }
            resolve_proc_section.proc_start = source_exp.begin.begin_pos
            resolve_proc_section.proc_end = source_exp.end.end_pos
          end
          super(node)
        end
      end
    end

    # Transform `interfaces [A, B, C]` to `implements A\nimplements B\nimplements C\n`
    class InterfacesToImplementsTransform < Transform
      PATTERN = /(?<indent>\s*)(?:interfaces) \[\s*(?<interfaces>(?:[a-zA-Z_0-9:\.,\s]+))\]/m
      def apply(input_text)
        input_text.gsub(PATTERN) do
          indent = $~[:indent]
          interfaces = $~[:interfaces].split(',').map(&:strip).reject(&:empty?)
          # Preserve leading newlines before the `interfaces ...`
          # call, but don't re-insert them between `implements` calls.
          extra_leading_newlines = "\n" * (indent[/^\n*/].length - 1)
          indent = indent.sub(/^\n*/m, "")
          interfaces_calls = interfaces
            .map { |interface| "\n#{indent}implements #{interface}" }
            .join
          extra_leading_newlines + interfaces_calls
        end
      end
    end

    # Transform `possible_types [A, B, C]` to `possible_types(A, B, C)`
    class PossibleTypesTransform < Transform
      PATTERN = /(?<indent>\s*)(?:possible_types) \[\s*(?<possible_types>(?:[a-zA-Z_0-9:\.,\s]+))\]/m
      def apply(input_text)
        input_text.gsub(PATTERN) do
          indent = $~[:indent]
          possible_types = $~[:possible_types].split(',').map(&:strip).reject(&:empty?)
          extra_leading_newlines = indent[/^\n*/]
          method_indent = indent.sub(/^\n*/m, "")
          type_indent = "  " + method_indent
          possible_types_call = "#{method_indent}possible_types(\n#{possible_types.map { |t| "#{type_indent}#{t},"}.join("\n")}\n#{method_indent})"
          extra_leading_newlines + trim_lines(possible_types_call)
        end
      end
    end

    class UpdateMethodSignatureTransform < Transform
      def apply(input_text)
        input_text.scan(/(?:input_field|field|return_field|connection|argument) .*$/).each do |field|
          matches = /(?<field_type>input_field|return_field|field|connection|argument) :(?<name>[a-zA-Z_0-9_]*)?(:?, +(?<return_type>([A-Za-z\[\]\.\!_0-9\(\)]|::|-> ?\{ ?| ?\})+))?(?<remainder>( |,|$).*)/.match(field)
          if matches
            name = matches[:name]
            return_type = matches[:return_type]
            remainder = matches[:remainder]
            field_type = matches[:field_type]
            with_block = remainder.gsub!(/\ do$/, '')

            remainder.gsub! /,$/, ''
            remainder.gsub! /^,/, ''
            remainder.chomp!

            if return_type
              non_nullable = return_type.sub! /(^|[^\[])!/, '\1'
              non_nullable ||= return_type.sub! /([^\[])\.to_non_null_type([^\]]|$)/, '\1'
              nullable = !non_nullable
              return_type = normalize_type_expression(return_type)
            else
              non_nullable = nil
              nullable = nil
            end

            input_text.sub!(field) do
              is_argument = ['argument', 'input_field'].include?(field_type)
              f = "#{is_argument ? 'argument' : 'field'} :#{name}"

              if return_type
                f += ", #{return_type}"
              end

              unless remainder.empty?
                f += ',' + remainder
              end

              if is_argument
                if nullable
                  f += ', required: false'
                elsif non_nullable
                  f += ', required: true'
                end
              else
                if nullable
                  f += ', null: true'
                elsif non_nullable
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
    # Remove double newline before `end`
    # Remove lines with whitespace only
    class RemoveExcessWhitespaceTransform < Transform
      def apply(input_text)
        input_text
          .gsub(/\n{3,}/m, "\n\n")
          .gsub(/do\n{2,}/m, "do\n")
          .gsub(/\n{2,}(\s*)end/m, "\n\\1end")
          .gsub(/\n +\n/m, "\n\n")
      end
    end

    # Skip this file if you see any `field`
    # helpers with `null: true` or `null: false` keywords
    # or `argument` helpers with `required:` keywords,
    # because it's already been transformed
    class SkipOnNullKeyword
      def skip?(input_text)
        input_text =~ /field.*null: (true|false)/ || input_text =~ /argument.*required: (true|false)/
      end
    end

    class Member
      def initialize(member, skip: SkipOnNullKeyword, type_transforms: DEFAULT_TYPE_TRANSFORMS, field_transforms: DEFAULT_FIELD_TRANSFORMS, clean_up_transforms: DEFAULT_CLEAN_UP_TRANSFORMS)
        GraphQL::Deprecation.warn "#{self.class} will be removed from GraphQL-Ruby 2.0 (but there's no point in using it after you've transformed your code, anyways)"
        @member = member
        @skip = skip
        @type_transforms = type_transforms
        @field_transforms = field_transforms
        @clean_up_transforms = clean_up_transforms
      end

      DEFAULT_TYPE_TRANSFORMS = [
        TypeDefineToClassTransform,
        MutationResolveProcToMethodTransform, # Do this before switching to class, so we can detect that its a mutation
        UnderscorizeMutationHashTransform,
        MutationDefineToClassTransform,
        NameTransform,
        InterfacesToImplementsTransform,
        PossibleTypesTransform,
        ProcToClassMethodTransform.new("coerce_input"),
        ProcToClassMethodTransform.new("coerce_result"),
        ProcToClassMethodTransform.new("resolve_type"),
      ]

      DEFAULT_FIELD_TRANSFORMS = [
        RemoveNewlinesTransform,
        RemoveMethodParensTransform,
        PositionalTypeArgTransform,
        ConfigurationToKwargTransform.new(kwarg: "property"),
        ConfigurationToKwargTransform.new(kwarg: "description"),
        ConfigurationToKwargTransform.new(kwarg: "deprecation_reason"),
        ConfigurationToKwargTransform.new(kwarg: "hash_key"),
        PropertyToMethodTransform,
        UnderscoreizeFieldNameTransform,
        ResolveProcToMethodTransform,
        UpdateMethodSignatureTransform,
        RemoveRedundantKwargTransform.new(kwarg: "hash_key"),
        RemoveRedundantKwargTransform.new(kwarg: "method"),
      ]

      DEFAULT_CLEAN_UP_TRANSFORMS = [
        RemoveExcessWhitespaceTransform,
        RemoveEmptyBlocksTransform,
      ]

      def upgrade
        type_source = @member.dup
        should_skip = @skip.new.skip?(type_source)
        # return the unmodified code
        if should_skip
          return type_source
        end
        # Transforms on type defn code:
        type_source = apply_transforms(type_source, @type_transforms)
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
        FieldFinder::DEFINITION_METHODS.each do |def_method|
          finder.locations[def_method].each do |name, (starting_idx, ending_idx)|
            field_source = type_source[starting_idx..ending_idx]
            field_sources << field_source
          end
        end
        # Here's a crazy thing: the transformation is pure,
        # so definitions like `argument :id, types.ID` can be transformed once
        # then replaced everywhere. So:
        # - make a unique array here
        # - use `gsub` after performing the transformation.
        field_sources.uniq!
        field_sources
      rescue Parser::SyntaxError
        puts "Error Source:"
        puts type_source
        raise
      end

      class FieldFinder < Parser::AST::Processor
        # These methods are definition DSLs which may accept a block,
        # each of these definitions is passed for transformation in its own right.
        # `field` and `connection` take priority. In fact, they upgrade their
        # own arguments, so those upgrades turn out to be no-ops.
        DEFINITION_METHODS = [:field, :connection, :input_field, :return_field, :argument]
        attr_reader :locations

        def initialize
          # Pairs of `{ { method_name => { name => [start, end] } }`,
          # since fields/arguments are unique by name, within their category
          @locations = Hash.new { |h,k| h[k] = {} }
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
            if @locations[method_name][name].nil?
              starting_idx = source_node.loc.expression.begin.begin_pos
              ending_idx = source_node.loc.expression.end.end_pos
              @locations[method_name][name] = [starting_idx, ending_idx]
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
