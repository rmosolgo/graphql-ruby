# frozen_string_literal: true
require "fileutils"
require "graphql/rake_task/validate"

module GraphQL
  # A rake task for dumping a schema as IDL or JSON.
  #
  # By default, schemas are looked up by name as constants using `schema_name:`.
  # You can provide a `load_schema` function to return your schema another way.
  #
  # `load_context:`, `only:` and `except:` are supported so that
  # you can keep an eye on how filters affect your schema.
  #
  # @example Dump a Schema to .graphql + .json files
  #   require "graphql/rake_task"
  #   GraphQL::RakeTask.new(schema_name: "MySchema")
  #
  #   # $ rake graphql:schema:dump
  #   # Schema IDL dumped to ./schema.graphql
  #   # Schema JSON dumped to ./schema.json
  #
  # @example Invoking the task from Ruby
  #   require "rake"
  #   Rake::Task["graphql:schema:dump"].invoke
  class RakeTask
    include Rake::DSL

    DEFAULT_OPTIONS = {
      namespace: "graphql",
      dependencies: nil,
      schema_name: nil,
      load_schema: ->(task) { Object.const_get(task.schema_name) },
      load_context: ->(task) { {} },
      only: nil,
      except: nil,
      directory: ".",
      idl_outfile: "schema.graphql",
      json_outfile: "schema.json",
    }

    # @return [String] Namespace for generated tasks
    attr_writer :namespace

    def rake_namespace
      @namespace
    end

    # @return [Array<String>]
    attr_accessor :dependencies

    # @return [String] By default, used to find the schema as a constant.
    # @see {#load_schema} for loading a schema another way
    attr_accessor :schema_name

    # @return [<#call(task)>] A proc for loading the target GraphQL schema
    attr_accessor :load_schema

    # @return [<#call(task)>] A callable for loading the query context
    attr_accessor :load_context

    # @return [<#call(member, ctx)>, nil] A filter for this task
    attr_accessor :only

    # @return [<#call(member, ctx)>, nil] A filter for this task
    attr_accessor :except

    # @return [String] target for IDL task
    attr_accessor :idl_outfile

    # @return [String] target for JSON task
    attr_accessor :json_outfile

    # @return [String] directory for IDL & JSON files
    attr_accessor :directory

    # Set the parameters of this task by passing keyword arguments
    # or assigning attributes inside the block
    def initialize(options = {})
      default_dependencies = if Rake::Task.task_defined?("environment")
        [:environment]
      else
        []
      end

      all_options = DEFAULT_OPTIONS
        .merge(dependencies: default_dependencies)
        .merge(options)
      all_options.each do |k, v|
        self.public_send("#{k}=", v)
      end

      if block_given?
        yield(self)
      end

      define_task
    end

    private

    # Use the provided `method_name` to generate a string from the specified schema
    # then write it to `file`.
    def write_outfile(method_name, file)
      schema = @load_schema.call(self)
      context = @load_context.call(self)
      result = schema.public_send(method_name, only: @only, except: @except, context: context)
      dir = File.dirname(file)
      FileUtils.mkdir_p(dir)
      File.write(file, result)
    end

    def idl_path
      File.join(@directory, @idl_outfile)
    end

    def json_path
      File.join(@directory, @json_outfile)
    end

    # Use the Rake DSL to add tasks
    def define_task
      namespace(@namespace) do
        namespace("schema") do
          desc("Dump the schema to IDL in #{idl_path}")
          task :idl => @dependencies do
            write_outfile(:to_definition, idl_path)
            puts "Schema IDL dumped into #{idl_path}"
          end

          desc("Dump the schema to JSON in #{json_path}")
          task :json => @dependencies do
            write_outfile(:to_json, json_path)
            puts "Schema JSON dumped into #{json_path}"
          end

          desc("Dump the schema to JSON and IDL")
          task :dump => [:idl, :json]
        end
      end
    end
  end
end
