# frozen_string_literal: true

require "json"
require "logger"
require "optparse"
require "set"
require "yaml"
require "yard"

module GraphQLDocs
  class Compatibility
    API_TYPES = %w[class module instance_method class_method].freeze

    def initialize(root: Dir.pwd)
      @root = File.expand_path(root)
    end

    def check(rdoc_index:, allowlist: nil)
      yard = yard_entries
      rdoc = rdoc_entries(rdoc_index)
      missing = yard - rdoc
      extra = rdoc - yard
      exceptions = load_allowlist(allowlist)
      unexpected_missing = missing.reject { |entry| exceptions.fetch("missing_from_rdoc", {}).key?(entry) }
      unexpected_extra = extra.reject { |entry| exceptions.fetch("extra_in_rdoc", {}).key?(entry) }

      result = {
        "missing_from_rdoc" => missing.sort,
        "extra_in_rdoc" => extra.sort,
        "unexpected_missing" => unexpected_missing.sort,
        "unexpected_extra" => unexpected_extra.sort,
      }
      report(result)
      result
    end

    private

    def yard_entries
      YARD::Registry.clear
      YARD::Logger.instance.level = ::Logger::ERROR
      YARD.parse(Dir[File.join(@root, "lib", "**", "*.rb")])
      YARD::Registry.all(:class, :module, :method).filter_map do |object|
        next if object.visibility == :private
        next if object.docstring.empty?
        next if object.respond_to?(:is_attribute?) && object.is_attribute?

        type = yard_type(object)
        next unless type

        [type, yard_name(object)]
      end.to_set
    end

    def yard_type(object)
      case object.type
      when :class, :module, :constant
        object.type.to_s
      when :method
        object.scope == :class ? "class_method" : "instance_method"
      end
    end

    def yard_name(object)
      object.type == :method ? object.path.to_s : object.path.to_s
    end

    def rdoc_entries(path)
      json = File.read(path).delete_prefix("var search_data = ").delete_suffix(";")
      data = JSON.parse(json)
      data.fetch("index").filter_map do |entry|
        type = entry["type"]
        next unless API_TYPES.include?(type)
        next if entry["snippet"].to_s.empty?

        [type, normalize_rdoc_name(type, entry.fetch("full_name"))]
      end.to_set
    end

    def normalize_rdoc_name(type, name)
      return name unless type == "class_method"

      name.sub(/::([^:]+)\z/, '.\\1')
    end

    def load_allowlist(path)
      return { "missing_from_rdoc" => {}, "extra_in_rdoc" => {} } unless path

      data = YAML.safe_load(File.read(path), permitted_classes: [], aliases: false) || {}
      %w[missing_from_rdoc extra_in_rdoc].each_with_object({}) do |key, allowlist|
        values = data.fetch(key, {})
        entries = values.is_a?(Hash) ? values.map { |name, reason| { "name" => name, "reason" => reason } } : values
        unless entries.is_a?(Array) && entries.all? { |entry| entry.is_a?(Hash) && entry["name"].is_a?(String) && entry["reason"].is_a?(String) && !entry["reason"].empty? }
          raise ArgumentError, "#{path}: #{key} must contain names with non-empty reasons"
        end
        allowlist[key] = entries.to_h { |entry| [entry.fetch("name"), entry.fetch("reason")] }
      end
    end

    def report(result)
      puts "Missing from RDoc: #{result.fetch("missing_from_rdoc").size}"
      puts "Extra in RDoc: #{result.fetch("extra_in_rdoc").size}"
      puts "Unexpected missing: #{result.fetch("unexpected_missing").size}"
      puts "Unexpected extra: #{result.fetch("unexpected_extra").size}"
      result.fetch("unexpected_missing").each { |entry| warn "missing: #{entry.inspect}" }
      result.fetch("unexpected_extra").each { |entry| warn "extra: #{entry.inspect}" }
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { root: Dir.pwd, strict: false }
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/compatibility.rb [options]"
    parser.on("--root PATH", "Repository root") { |path| options[:root] = path }
    parser.on("--rdoc PATH", "RDoc search_data.js") { |path| options[:rdoc] = path }
    parser.on("--allowlist PATH", "YAML API exception allowlist") { |path| options[:allowlist] = path }
    parser.on("--json PATH", "Write the comparison report as JSON") { |path| options[:json] = path }
    parser.on("--strict", "Fail when a difference is not allowlisted") { options[:strict] = true }
  end.parse!

  abort "--rdoc is required" unless options[:rdoc]
  result = GraphQLDocs::Compatibility.new(root: options[:root]).check(rdoc_index: options[:rdoc], allowlist: options[:allowlist])
  File.write(options[:json], JSON.pretty_generate(result) + "\n") if options[:json]
  if options[:strict] && (result.fetch("unexpected_missing").any? || result.fetch("unexpected_extra").any?)
    exit 1
  end
end
