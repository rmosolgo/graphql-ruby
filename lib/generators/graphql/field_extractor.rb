# frozen_string_literal: true
require 'rails/generators/base'

module Graphql
  module Generators
    module FieldExtractor
      def fields
        columns = []
        if (model_columns = klass&.columns)
          filter = if defined?(ActiveSupport::ParameterFilter)
            fp = if defined?(Rails) && Rails.application && (app_config = Rails.application.config.filter_parameters).present? && !app_config.empty?
              app_config
            elsif ActiveSupport.respond_to?(:filter_parameters)
              ActiveSupport.filter_parameters
            else
              []
            end
            ActiveSupport::ParameterFilter.new(fp, mask: nil)
          else
            nil
          end
          columns += model_columns
            .select { |c| filter ? filter.filter_param(c.name, c.name) : true }
            .map { |c| generate_column_string(c) }
        end
        columns + custom_fields
      end

      def generate_column_string(column)
        name = column.name
        required = column.null ? "" : "!"
        type = column_type_string(column)
        "#{name}:#{required}#{type}"
      end

      def column_type_string(column)
        column.name == "id" ? "ID" : column.type.to_s.camelize
      end

      def klass
        @klass ||= Module.const_get(name.camelize)
      rescue NameError
        @klass = nil
      end
    end
  end
end
