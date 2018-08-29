# frozen_string_literal: true
module GraphQL
  class Query
    class InputValidationResult
      attr_accessor :problems
      attr_accessor :extensions

      def valid?
        @problems.nil?
      end

      def add_problem(explanation, path = nil)
        @problems ||= []
        @problems.push({ "path" => path || [], "explanation" => explanation })
      end

      def add_extensions(extensions)
        @extensions ||= []
        @extensions.push(extensions)
      end

      def merge_result!(path, inner_result)
        return if inner_result.valid?

        inner_result.problems.each do |p|
          item_path = [path, *p["path"]]
          add_problem(p["explanation"], item_path)
        end

        # extensions are optional so don't attempt to
        # merge them if they don't exist
        if inner_result.extensions
          inner_result.extensions.each do |e|
            item_path = [path, *e["path"]]
            add_extensions(e, item_path)
          end
        end
      end
    end
  end
end
