# frozen_string_literal: true
module GraphQLSite
  module APIDoc
    API_DOC_ROOT = "http://www.rubydoc.info/gems/graphql/"

    def api_doc(input)
      doc_path = input
        .gsub("::", "/")                        # namespaces
        .sub(/#(.+)$/, "#\\1-instance_method")  # instance methods
        .sub(/\.(.+)$/, "#\\1-class_method")    # class methods

      %|<a href="#{API_DOC_ROOT}#{doc_path}" target="_blank"><code>#{input}</code></a>|
    end
  end
end

Liquid::Template.register_filter(GraphQLSite::APIDoc)
