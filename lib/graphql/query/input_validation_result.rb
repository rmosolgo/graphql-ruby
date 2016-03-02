class GraphQL::Query
  class InputValidationResult
    attr_accessor :problems

    def is_valid?
      @problems.nil?
    end

    def add_problem(explanation, path = nil)
      @problems ||= []
      @problems.push({ 'path' => path || [], 'explanation' => explanation })
    end

    def merge_result!(path, inner_result)
      return if inner_result.problems.nil?

      inner_result.problems.each do |p|
        item_path = [path, *p['path']]
        add_problem(p['explanation'], item_path)
      end
    end
  end
end
