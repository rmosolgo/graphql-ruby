# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasDirectives
        # Create an instance of `dir_class` for `self`, using `options`.
        #
        # It removes a previously-attached instance of `dir_class`, if there is one.
        #
        # @return [void]
        def directive(dir_class, **options)
          @own_directives ||= []
          remove_directive(dir_class)
          @own_directives << dir_class.new(self, **options)
          nil
        end

        # Remove an attached instance of `dir_class`, if there is one
        # @param dir_class [Class<GraphQL::Schema::Directive>]
        # @return [viod]
        def remove_directive(dir_class)
          @own_directives && @own_directives.reject! { |d| d.is_a?(dir_class) }
          nil
        end

        NO_DIRECTIVES = [].freeze

        def directives
          case self
          when Class
            inherited_directives = if superclass.respond_to?(:directives)
              superclass.directives
            else
              NO_DIRECTIVES
            end
            if inherited_directives.any? && @own_directives
              dirs = []
              merge_directives(dirs, inherited_directives)
              merge_directives(dirs, @own_directives)
              dirs
            elsif @own_directives
              @own_directives
            elsif inherited_directives.any?
              inherited_directives
            else
              NO_DIRECTIVES
            end
          when Module
            dirs = nil
            self.ancestors.reverse_each do |ancestor|
              if ancestor.respond_to?(:own_directives) &&
                  (anc_dirs = ancestor.own_directives).any?
                dirs ||= []
                merge_directives(dirs, anc_dirs)
              end
            end
            if own_directives
              dirs ||= []
              merge_directives(dirs, own_directives)
            end
            dirs || NO_DIRECTIVES
          when HasDirectives
            @own_directives || NO_DIRECTIVES
          else
            raise "Invariant: how could #{self} not be a Class, Module, or instance of HasDirectives?"
          end
        end

        protected

        def own_directives
          @own_directives
        end

        private

        # Modify `target` by adding items from `dirs` such that:
        # - Any name conflict is overriden by the incoming member of `dirs`
        # - Any other member of `dirs` is appended
        # @param target [Array<GraphQL::Schema::Directive>]
        # @param dirs [Array<GraphQL::Schema::Directive>]
        # @return [void]
        def merge_directives(target, dirs)
          dirs.each do |dir|
            if (idx = target.find_index { |d| d.graphql_name == dir.graphql_name })
              target.slice!(idx)
              target.insert(idx, dir)
            else
              target << dir
            end
          end
          nil
        end
      end
    end
  end
end
