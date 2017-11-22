# frozen_string_literal: true

module GraphQL
  module Upgrader
    class Member
      def initialize(member)
        @member = member
      end

      def upgrade
        transformable = member.dup
        transformable = transform_to_class transformable
        transformable = transform_or_remove_name transformable
        transformable = simplify_field_definition_for_easier_processing transformable
        transformable = move_the_type_from_the_block_to_the_field transformable

        transformable.scan(/(?:field|connection|argument) .*$/).each do |field|
          field_regex = /(?<field_type>field|connection|argument) :(?<name>[a-zA-Z_0-9]*)?, (?<return_type>.*?)(?<thing>,|$|\})(?<remainder>.*)/

          if (matches = field_regex.match(field))
            name = matches[:name]
            return_type = matches[:return_type]
            remainder = matches[:remainder]
            thing = matches[:thing]
            field_type = matches[:field_type]

            # This is a small bug in the regex. Ideally the `do` part would only be in the remainder.
            with_block = remainder.gsub!(/\ do$/, '') || return_type.gsub!(/\ do$/, '')

            nullable = !!(return_type.gsub! '!', '')
            return_type.gsub! 'types.', ''
            return_type.gsub! 'types[', '['

            nullable_as_keyword = ", null: #{!nullable.to_s}"
            connection_as_keyword = field_type == 'connection' ? ', connection: true' : ''
            field_type = field_type == 'argument' ? 'argument' : 'field'

            transformable.sub!(field) do
              "#{field_type} :#{name}, #{return_type}#{thing}#{remainder}#{nullable_as_keyword}#{connection_as_keyword}#{with_block ? ' do' : ''}"
            end
          end
        end

        transformable
      end

      def upgradeable?
        return false if member.include? '< GraphQL::Schema::'
        return false if member.include? '< BaseObject'
        return false if member.include? '< BaseInterface'
        return false if member.include? '< BaseEnum'

        true
      end

      private

      def move_the_type_from_the_block_to_the_field(transformable)
        transformable.gsub(
          /(?<field>(?:field|connection|argument) :(?:[a-zA-Z_0-9]*)) do(?<block_contents>.*?)[ ]*type (?<return_type>.*?)\n/m
        ) do
          field = $~[:field]
          block_contents = $~[:block_contents]
          return_type = $~[:return_type]

          "#{field}, #{return_type} do#{block_contents}"
        end
      end

      def simplify_field_definition_for_easier_processing(transformable)
        transformable.gsub(/(?<field>(?:field|connection|argument).*?),\n(\s*)(?<next_line>(:?"|field)(.*))/) do
          field = $~[:field].chomp
          next_line = $~[:next_line]

          "#{field}, #{next_line}"
        end
      end

      def transform_to_class(transformable)
        transformable.sub(
          /([a-zA-Z_0-9:]*) = GraphQL::(Object|Interface|Enum|Union)Type\.define do/, 'class \1 < Base\2'
        )
      end

      def transform_or_remove_name(transformable)
        if (matches = transformable.match(/class (?<type_name>[a-zA-Z_0-9]*) < Base(Object|Interface|Enum|Union)/))
          type_name = matches[:type_name]
          type_name_without_the_type_part = type_name.gsub(/Type$/, '')

          if matches = transformable.match(/name ('|")(?<type_name>.*)('|")/)
            name = matches[:type_name]
            if type_name_without_the_type_part != name
              transformable = transformable.sub(/name (.*)/, 'graphql_name \1')
            else
              transformable = transformable.sub(/\s*name ('|").*('|")/, '')
            end
          end
        end

        transformable
      end

      attr_reader :member
    end
  end
end
