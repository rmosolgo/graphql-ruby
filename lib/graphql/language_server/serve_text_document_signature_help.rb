# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # The client requests code completion.
    # Call out to the provider and send the response to the client.
    class ServeTextDocumentSignatureHelp < Response
      def response
        document_position = DocumentPosition.from_params(request[:params], server: server)
        if document_position.nil?
          nil
        else
          sig_help = SignatureHelp.new(document_position: document_position)
          active_signature = sig_help.active_signature
          if active_signature
            LSP::Interface::SignatureHelp.new(
              signatures: [to_lsp(active_signature)],
            )
          else
            nil
          end
        end
      end

      private

      # @param input [GraphQL::Field, GraphQL::InputObjectType]
      def to_lsp(input)
        case input
        when GraphQL::Field
          LSP::Interface::SignatureInformation.new(
            label: "#{input.name}(#{input.arguments.map { |n, arg| "#{n}: #{arg.type.to_s}" }.join(", ")})",
            documentation: "#{input.description || ""} (#{input.type.to_s})",
            parameters: to_lsp_parameters(input.arguments)
          )
        when GraphQL::InputObjectType
          LSP::Interface::SignatureInformation.new(
            label: "{#{input.arguments.map { |n, arg| "#{n}: #{arg.type.to_s}" }.join(", ")}}",
            documentation: "#{input.name}#{input.description ? ": #{input.description}" : ""}",
            parameters: to_lsp_parameters(input.arguments)
          )
        else
          raise "Unexpected input: #{input.class.name} (#{input})"
        end
      end

      def to_lsp_parameters(arguments)
        arguments.map do |name, arg|
         LSP::Interface::ParameterInformation.new(
           label: arg.name,
           documentation: arg.description,
         )
       end
     end
    end
  end
end
