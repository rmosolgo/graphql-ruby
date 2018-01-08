# frozen_string_literal: true

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
          # Remove the proc wrapper, then re-apply it
          unwrapped = type_expr
            .sub(/\A->\s?\{\s*/, "")
            .sub(/\s*\}/, "")
          # TODO do we have to keep this?
          "-> { #{normalize_type_expression(unwrapped, preserve_bang: preserve_bang)} }"
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
        @replace_pattern = "class \\1 < #{base_class_pattern}"
      end

      def apply(input_text)
        input_text.sub(
          /([a-zA-Z_0-9:]*) = GraphQL::#{GRAPHQL_TYPES}Type\.define do/,
          @replace_pattern
        )
      end
    end

    # Remove `name "Something"` if it is redundant with the class name.
    # Or, if it is not redundant, move it to `graphql_name "Something"`.
    class NameTransform < Transform
      def apply(transformable)
        if (matches = transformable.match(/class (?<type_name>[a-zA-Z_0-9:]*) < Types::Base#{GRAPHQL_TYPES}/))
          type_name = matches[:type_name]
          # Get the name without any prefixes or suffixes
          type_name_without_the_type_part = type_name.split('::').last.gsub(/Type$/, '')
          # Find an overridden name value
          if matches = transformable.match(/name ('|")(?<overridden_name>.*)('|")/)
            name = matches[:overridden_name]
            if type_name_without_the_type_part != name
              # If the overridden name is still required, use `graphql_name` for it
              transformable = transformable.sub(/name (.*)/, 'graphql_name \1')
            else
              # Otherwise, remove it altogether
              transformable = transformable.sub(/\s*name ('|").*('|")/, '')
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

    # Transform `interfaces [A, B, C]` to `implements A\nimplements B\nimplements C\n`
    class InterfacesToImplementsTransform < Transform
      def apply(input_text)
        input_text.gsub(
          /(?<indent>\s*)(?:interfaces) \[(?<interfaces>(?:[a-zA-Z_0-9:]+)(?:,\s*[a-zA-Z_0-9:]+)*)\]/
        ) do
          indent = $~[:indent]
          interfaces = $~[:interfaces].split(',').map(&:strip)

          interfaces.map do |interface|
            "#{indent}implements #{interface}"
          end.join
        end
      end
    end

    class UpdateMethodSignatureTransform < Transform
      def apply(input_text)
        input_text.scan(/(?:input_field|field|connection|argument) .*$/).each do |field|
          matches = /(?<field_type>input_field|field|connection|argument) :(?<name>[a-zA-Z_0-9_]*)?, (?<return_type>.*?(?:,|$|\}))(?<remainder>.*)/.match(field)
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
        input_text.gsub(/\s*do\s*end\s*/m, "")
      end
    end

    class Member
      def initialize(member)
        @member = member
      end

      def upgrade
        transformable = @member.dup
        transformable = TypeDefineToClassTransform.new.apply(transformable)
        transformable = NameTransform.new.apply(transformable)
        transformable = RemoveNewlinesTransform.new.apply(transformable)
        transformable = PositionalTypeArgTransform.new.apply(transformable)
        transformable = ConfigurationToKwargTransform.new(kwarg: "property").apply(transformable)
        transformable = ConfigurationToKwargTransform.new(kwarg: "description").apply(transformable)
        transformable = PropertyToMethodTransform.new.apply(transformable)
        transformable = InterfacesToImplementsTransform.new.apply(transformable)
        transformable = UpdateMethodSignatureTransform.new.apply(transformable)
        transformable = RemoveEmptyBlocksTransform.new.apply(transformable)
        transformable
      end

      def upgradeable?
        return false if @member.include? '< GraphQL::Schema::'
        return false if @member =~ /< Types::Base#{GRAPHQL_TYPES}/

        true
      end
    end
  end
end
