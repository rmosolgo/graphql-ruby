module GraphQL
  # @example A reusable GraphQL::Function attached as a field
  #   class FindRecord < GraphQL::Function
  #     attr_reader :type
  #
  #     def initialize(model:, type:)
  #       @model = model
  #       @type = type
  #     end
  #
  #     argument :id, GraphQL::Id
  #
  #     def resolve(obj, args, ctx)
  #        @model.find(args.id)
  #     end
  #   end
  #
  #   QueryType = GraphQL::ObjectType.define do
  #     name "Query"
  #     field :post, function: FindRecord.new(model: Post, type: PostType)
  #     field :post, function: FindRecord.new(model: Comment, type: CommentType)
  #   end
  class Function
    def arguments
      self.class.arguments
    end

    def type
      self.class.type
    end

    def call(obj, args, ctx)
      raise NotImplementedError
    end

    def description
      self.class.description
    end

    def deprecation_reason
      self.class.deprecation_reason
    end

    def complexity
      self.class.complexity
    end

    class << self
      def own_arguments
        @own_arguments ||= {}
      end

      def argument(*args, **kwargs, &block)
        argument = GraphQL::Argument.from_dsl(*args, **kwargs, &block)
        own_arguments[argument.name] = argument
      end

      def arguments
        if parent_function?
          own_arguments.merge(superclass.arguments)
        else
          own_arguments
        end
      end

      def type(premade_type = nil, &block)
        if block_given?
          @type = GraphQL::ObjectType.define(&block)
        elsif premade_type
          @type = premade_type
        else
          @type
        end
      end

      def self.inherited_value(name)
        self.class_eval <<-RUBY
          def #{name}(new_value = nil)
            if new_value
              @#{name} = new_value
            elsif parent_function?
              @#{name} || superclass.#{name}
            else
              @#{name}
            end
          end
        RUBY
      end

      inherited_value(:description)
      inherited_value(:deprecation_reason)
      inherited_value(:complexity)

      private

      def parent_function?
        superclass <= GraphQL::Function
      end
    end
  end
end
