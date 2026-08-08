# frozen_string_literal: true

require "optparse"

module GraphQLDocs
  class SourceChecker
    def initialize(root: Dir.pwd)
      @root = File.expand_path(root)
    end

    def check
      errors = []
      ruby_files.each do |path|
        File.foreach(path).with_index(1) do |line, number|
          errors << "#{path}:#{number}: YARD tag" if line.match?(/^\s*# @(?:[A-Za-z0-9_!]+)/)
        end
      end
      markdown_files.each do |path|
        text = File.read(path)
        errors << "#{path}: Liquid tag" if text.match?(/\{%|\{%{2}/)
      end
      errors.each { |error| warn error }
      errors
    end

    private

    def ruby_files
      Dir[File.join(@root, "lib", "**", "*.rb")]
    end

    def markdown_files
      Dir[File.join(@root, "guides", "**", "*.md")] + Dir[File.join(@root, "docs", "**", "*.md")]
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { root: Dir.pwd }
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/check.rb [options]"
    parser.on("--root PATH", "Repository root") { |path| options[:root] = path }
  end.parse!
  exit 1 unless GraphQLDocs::SourceChecker.new(root: options.fetch(:root)).check.empty?
end
