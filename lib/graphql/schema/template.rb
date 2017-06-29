# frozen_string_literal: true

module GraphQL
  class Schema
    # @see {Schema.from_definition} for loading GraphQL schema from GraphQL IDL
    # @see {Template::Helpers} for ERB definition helpers
    # @api private
    class Template
      # @param erb_template [String]
      # @param helpers [Module] extra helper methods for ERB template
      # @return [String] Reified GraphQL
      def self.run(erb_template, helpers: nil)
        template_class = self
        template_class = Class.new(template_class) {
          # Include built-in helpers
          include Helpers
          # Include user-provided helpers
          if helpers
            include helpers
          end
        }
        template_class.new(erb_template).run
      end

      # @param erb_template [String] GraphQL with embedded Ruby
      def initialize(erb_template)
        @erb_template = erb_template
        @result = ""
      end

      module Helpers
        # @return [String] Rendered ERB
        def run
          ERB.new(@erb_template, 0, "", "@result").result(binding)
          @result
        end

        # Define a default-configuration Relay connection type for `type_name`
        # @param type_name [String]
        # @return [String] GraphQL IDL for a connection type
        def connection_type(type_name)
          conn = type("#{type_name}Connection", edges: "[#{type_name}Edge!]!", pageInfo: "PageInfo!")
          edge = type("#{type_name}Edge", cursor: "ID!", node: "#{type_name}!")
          conn + "\n" + edge
        end

        # Generate GraphQL definition for `name => return_type_name` pairs.
        #
        # @example Generate a connection of posts
        #   <%= connection_field(posts: :Posts) %>
        #   # => "posts(after: ID, before: ID, first: Int, last: Int): PostsConnection"
        #
        # @param fields [Hash<[String, Symbol] => [String, Symbol]]
        # @return [String] GraphQL IDL definition for connection fields
        def connection_field(fields)
          graphql = fields.map do |name, type|
            field(name, {after: :ID, before: :ID, first: :Int, last: :Int}, "#{type}Connection!")
          end
          graphql.join("\n  ")
        end

        # @return [String] GraphQL code for Relay's `PageInfo` type
        def page_info
          @page_info ||= type("PageInfo", {startCursor: "ID!", endCursor: "ID!", hasNextPage: "Boolean!", hasPreviousPage: "Boolean!"})
        end

        # Generate code for a GraphQL object type named `name`
        # with fields described by `fields`
        #
        # @see {#field} for field options
        # @param name [String]
        # @param field [Hash<String, Symbol => String, Symbol, Array(Hash, [String, Symbol])>]
        # @return [String] GraphQL code for described type
        def type(name, fields)
          field_defns = fields
            .map { |name, returns|
              field_code = case returns
              when Array
                # Support name: [args, return_type]
                field(name, returns[0], returns[1])
              when String, Symbol
                field(name, returns)
              else
                raise "Unexpected field description: #{name} => #{returns}"
              end
              "\n  #{field_code}"
            }
            .sort
            .join

          "type #{name} {#{field_defns}\n}\n"
        end

        # @param field_name [String]
        # @param arguments [Hash<String, Symbol => String, Symbol>]
        # @param return_type_name [String]
        # @return [String] GraphQL IDL code for this field
        def field(field_name, arguments = {}, return_type_name)
          arg_string = if arguments.any?
            str = arguments
              .sort_by { |name, type| name.to_s }
              .map { |name, type| "#{name}: #{type}" }
              .join(",")
            "(#{str})"
          else
            ""
          end
          "#{field_name}#{arg_string}: #{return_type_name}"
        end
      end
    end
  end
end
