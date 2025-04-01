# frozen_string_literal: true
module Graphql
  class Dashboard < Rails::Engine
    module Installable
      def self.included(child_module)
        child_module.before_action(:check_installed)
      end

      def feature_installed?
        raise "Implement #{self.class}#feature_installed? to check whether this should render `not_installed` or not."
      end

      def check_installed
        if !feature_installed?
          @component_header_html = self.class::INSTALLABLE_COMPONENT_HEADER_HTML
          @component_message_html = self.class::INSTALLABLE_COMPONENT_MESSAGE_HTML
          render "graphql/dashboard/not_installed"
        end
      end
    end
  end
end
