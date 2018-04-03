# frozen_string_literal: true

module GraphQL
  class Schema
    # This base class accepts configuration for a mutation root field,
    # then it can be hooked up to your mutation root object type.
    #
    # If you want to customize how this class generates types, in your base class,
    # override the various `generate_*` methods.
    #
    # @see {GraphQL::Schema::RelayClassicMutation} for an extension of this class with some conventions built-in.
    #
    # @example Creating a comment
    #  # Define the mutation:
    #  class Mutations::CreateComment < GraphQL::Schema::Mutation
    #    argument :body, String, required: true
    #    argument :post_id, ID, required: true
    #
    #    field :comment, Types::Comment, null: true
    #    field :error_messages, [String], null: false
    #
    #    def resolve(body:, post_id:)
    #      post = Post.find(post_id)
    #      comment = post.comments.build(body: body, author: context[:current_user])
    #      if comment.save
    #        # Successful creation, return the created object with no errors
    #        {
    #          comment: comment,
    #          errors: [],
    #        }
    #      else
    #        # Failed save, return the errors to the client
    #        {
    #          comment: nil,
    #          errors: comment.errors.full_messages
    #        }
    #      end
    #    end
    #  end
    #
    #  # Hook it up to your mutation:
    #  class Types::Mutation < GraphQL::Schema::Object
    #    field :create_comment, mutation: Mutations::CreateComment
    #  end
    #
    #  # Call it from GraphQL:
    #  result = MySchema.execute <<-GRAPHQL
    #  mutation {
    #    createComment(postId: "1", body: "Nice Post!") {
    #      errors
    #      comment {
    #        body
    #        author {
    #          login
    #        }
    #      }
    #    }
    #  }
    #  GRAPHQL
    #
    class Mutation < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::HasFields
      extend GraphQL::Schema::Member::HasArguments

      # @param object [Object] the initialize object, pass to {Query.initialize} as `root_value`
      # @param context [GraphQL::Query::Context]
      def initialize(object:, context:, arguments:)
        @object = object
        @context = context
      end

      # @return [Object] the root value of the operation
      attr_reader :object

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # Do the work. Everything happens here.
      # @return [Hash] A key for each field in the return type
      # @return [Object] An object corresponding to the return type
      def resolve(**args)
        raise NotImplementedError, "#{self.class.name}#resolve should execute side effects and return a Symbol-keyed hash"
      end

      class << self
        # Override the method from HasFields to support `field: Mutation.field`, for backwards compat.
        #
        # If called without any arguments, returns a `GraphQL::Field`.
        # @see {GraphQL::Schema::Member::HasFields.field} for default behavior
        def field(*args, &block)
          if args.none? && !block_given?
            graphql_field.graphql_definition
          else
            super(*args, &block)
          end
        end

        # Call this method to get the derived return type of the mutation,
        # or use it as a configuration method to assign a return type
        # instead of generating one.
        # @param new_payload_type [Class, nil] If a type definition class is provided, it will be used as the return type of the mutation field
        # @return [Class] The object type which this mutation returns.
        def payload_type(new_payload_type = nil)
          if new_payload_type
            @payload_type = new_payload_type
          end
          @payload_type ||= generate_payload_type
        end

        # @return [GraphQL::Schema::Field] The generated field instance for this mutation
        # @see {GraphQL::Schema::Field}'s `mutation:` option, don't call this directly
        def graphql_field
          @graphql_field ||= generate_field
        end

        # @param new_name [String, nil] if present, override the class name to set this value
        # @return [String] The name of this mutation in the GraphQL schema (used for naming derived types and fields)
        def graphql_name(new_name = nil)
          if new_name
            @graphql_name = new_name
          end
          @graphql_name ||= self.name.split("::").last
        end

        # An object class to use for deriving payload types
        # @param new_class [Class, nil] Defaults to {GraphQL::Schema::Object}
        # @return [Class]
        def object_class(new_class = nil)
          if new_class
            @object_class = new_class
          end
          @object_class || (superclass.respond_to?(:object_class) ? superclass.object_class : GraphQL::Schema::Object)
        end

        # Additional info injected into {#resolve}
        # @see {GraphQL::Schema::Field#extras}
        def extras(new_extras = nil)
          if new_extras
            @extras = new_extras
          end
          @extras || []
        end

        private

        # Build a subclass of {.object_class} based on `self`.
        # This value will be cached as `{.payload_type}`.
        # Override this hook to customize return type generation.
        def generate_payload_type
          mutation_name = graphql_name
          mutation_fields = fields
          mutation_class = self
          Class.new(object_class) do
            graphql_name("#{mutation_name}Payload")
            description("Autogenerated return type of #{mutation_name}")
            mutation(mutation_class)
            mutation_fields.each do |name, f|
              field(name, field: f)
            end
          end
        end

        # This name will be used for the {.graphql_field}.
        def field_name
          graphql_name.sub(/^[A-Z]/, &:downcase)
        end

        # Build an instance of {.field_class} which will be used to execute this mutation.
        # To customize field generation, override this method.
        def generate_field
          # TODO support deprecation_reason
          self.field_class.new(
            field_name,
            payload_type,
            description,
            resolve: self.method(:resolve_field),\
            mutation_class: self,
            arguments: arguments,
            null: true,
          )
        end

        # This is basically the `.call` behavior for the generated field,
        # instantiating the Mutation class and calling its {#resolve} method
        # with Ruby keyword arguments.
        def resolve_field(obj, args, ctx)
          mutation = self.new(object: obj, arguments: args, context: ctx.query.context)
          ruby_kwargs = args.to_kwargs
          extras.each { |e| ruby_kwargs[e] = ctx.public_send(e) }
          mutation.resolve(**ruby_kwargs)
        end
      end
    end
  end
end
