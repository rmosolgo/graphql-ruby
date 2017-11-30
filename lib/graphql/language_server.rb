# frozen_string_literal: true
begin
  require "language_server-protocol"
rescue LoadError
  warn <<-ERR
GraphQL::LanguageServer requires an additional dependency:

    gem "language_server-protocol"

Please add it to your project and try again.
ERR
  raise
end

require "logger"
require "graphql"
require "graphql/language_server/completion_suggestion"
require "graphql/language_server/member"
require "graphql/language_server/reloader"
require "graphql/language_server/response"
require "graphql/language_server/serve_initialize"
require "graphql/language_server/serve_shutdown"
require "graphql/language_server/serve_text_document_completion"
require "graphql/language_server/serve_text_document_did_change"

module GraphQL
  # One instance of this class is started in a long-running process.
  class LanguageServer
    # The class var is not a mistake --
    # only one instance of this class should _ever_ be started.
    if !defined?(@@started)
      @@started = false
    end

    LSP = ::LanguageServer::Protocol
    attr_reader :input_type_names, :logger

    def initialize
      # { String => String }, URI to content
      @file_content_cache = {}
      @logger = self.class.logger || Logger.new($stdout)
      @schema = self.class.schema
      reload_globs = self.class.reload_globs || []
      if self.class.development_mode
        reload_globs << __FILE__.sub(".rb", "/**/*.rb")
      end
      @reloader = Reloader.new(globs: reload_globs, logger: @logger)
      prepare(force: true)
    end

    # Reset project state
    def prepare(force: false)
      reloaded = @reloader.reload
      if !(reloaded || force)
        return
      end
      @logger.info("#prepare")
      @types = {}
      @input_type_names = []
      @schema.types.each do |name, t|
        @types[name] = t
        if t.kind.input?
          @input_type_names << name
        end
      end

      # Roots by symbol:
      [:query, :mutation, :subscription].each do |root_sym|
        if (root_type = @schema.public_send(root_sym))
          @types[root_sym] = root_type
        end
      end
    end

    def cache_content(uri, content = nil)
      if content
        @file_content_cache[uri] = content
      else
        @file_content_cache[uri]
      end
    end

    def type(name)
      @types[name]
    end

    def start
      if @@started
        return
      else
        @@started = true
      end
      writer = LSP::Transport::Stdio::Writer.new
      reader = LSP::Transport::Stdio::Reader.new
      @logger.debug("*** starting")
      reader.read do |request|
        begin
          @logger.info("*** recd #{request}")
          prepare
          # Turn the method name into a class name
          camelized_request_name = request[:method]
            .split("/")
            .map { |s| s[0].capitalize + s[1..-1] }
            .join

          response_class_name = "Serve#{camelized_request_name}"
          @logger.debug("Looking up class: #{response_class_name}")
          response_class = begin
            self.class.const_get(response_class_name)
          rescue NameError
            nil
          end

          if response_class
            response_obj = response_class.new(server: self, request: request, logger: @logger)
            result = response_obj.response
            if result
              @logger.debug("Response ##{response_class}: #{result}")
              writer.write(id: request[:id], result: result)
            else
              @logger.debug("No response from #{response_class} (#{result.inspect})")
            end
          else
            @logger.debug "Skipping event #{request[:method]} / ##{response_class_name} (#{self.class.constants})"
          end
        rescue StandardError => err
          @logger.error("Responding with error: #{err}\n#{err.backtrace.join("\n")}")
          writer.write(
            id: request[:id],
            error: LSP::Interface::ResponseError.new(
              code: LSP::Constant::ErrorCodes::INTERNAL_ERROR,
              message: ([err.message] + [err.backtrace]).join("\n")
            )
          )
        end
      end
    end

    class << self
      attr_accessor :logger, :reload_globs, :development_mode, :schema
    end
  end
end
