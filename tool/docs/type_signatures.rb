# frozen_string_literal: true

require "optparse"

module GraphQLDocs
  class TypeSignatureMigrator
    SECTION_NAMES = ["Parameters", "Options", "Returns", "Yields", "Attributes"].freeze
    SECTION = /^\s*\*\*(#{SECTION_NAMES.join("|")})\*\*\s*$/.freeze
    ENTRY = /^\s*-\s+`([^`]+)`(?:\s+\(`([^`]+)`\))?/.freeze
    METHOD = /\bdef\s+(?:self\.)?([^\s(]+)(?:\((.*?)\))?/m.freeze
    ATTRIBUTE = /\battr_(?:reader|writer|accessor)\s+(.+)/.freeze

    attr_reader :paths

    def initialize(root: Dir.pwd, paths: nil)
      @root = File.expand_path(root)
      @paths = paths || Dir[File.join(@root, "lib", "**", "*.rb")].sort
    end

    def run(write: false)
      @paths.map do |path|
        original = File.read(path)
        converted = migrate(original)
        File.write(path, converted) if write && converted != original
        [path, original != converted]
      end
    end

    def migrate(source)
      lines = source.lines
      output = []
      index = 0
      while index < lines.length
        unless comment_line?(lines[index])
          output << lines[index]
          index += 1
          next
        end

        block_start = index
        index += 1 while index < lines.length && comment_line?(lines[index])
        block = lines[block_start...index]
        declaration = declaration_after(lines, index)
        signature = signature_for(block, declaration)
        output.concat(add_signature(block, signature))
      end
      output.join
    end

    private

    def comment_line?(line)
      line.match?(/^\s*#(?:\s|$)/)
    end

    def declaration_after(lines, index)
      return "" unless index < lines.length
      return "" unless lines[index].match?(/^\s*(?:def\b|attr_(?:reader|writer|accessor)\b)/)

      declaration = +""
      while index < lines.length && declaration.length < 2_000
        declaration << lines[index]
        index += 1
        break if balanced_parentheses?(declaration)
      end
      declaration
    end

    def balanced_parentheses?(text)
      depth = 0
      text.each_char do |character|
        depth += 1 if character == "("
        depth -= 1 if character == ")"
      end
      depth.zero?
    end

    def signature_for(block, declaration)
      return if declaration.empty? || declaration.include?(":nodoc:") || block.any? { |line| line.include?(":nodoc:") }

      sections = typed_sections(block)
      return if sections.empty?

      if (method = declaration.match(METHOD))
        method_name = method[1]
        parameters = method_parameters(declaration, method)
        arguments = parameters.map { |parameter| format_parameter(parameter, sections) }
        result_type = return_type(sections)
        return "#{method_name}(#{arguments.join(", ")})#{result_type ? " -> #{result_type}" : ""}"
      end

      return unless (attribute = declaration.match(ATTRIBUTE))
      name = attribute[1].split(",", 2).first.strip.sub(/\A:/, "")
      type = sections.fetch("Returns", []).filter_map(&:first).first
      return unless type

      "#{name} -> #{normalize_type(type)}"
    end

    def typed_sections(block)
      sections = Hash.new { |hash, key| hash[key] = [] }
      section = nil
      block.each do |line|
        text = line.sub(/^\s*# ?/, "").chomp
        if (match = text.match(SECTION))
          section = match[1]
        elsif section && (entry = text.match(ENTRY))
          sections[section] << [entry[1], entry[2]]
        end
      end
      sections.delete_if { |_name, entries| entries.empty? }
    end

    def method_parameters(declaration, method)
      params = method[2]
      return [] unless params

      params = params.strip
      return [] if params.empty?

      split_top_level(params).map do |parameter|
        parameter = parameter.strip
        name = parameter[/\A(?:\*{0,2}|&)?([a-zA-Z_]\w*[!?=]?|\.\.\.)/, 1]
        {source: parameter, name: name}
      end
    end

    def split_top_level(text)
      values = []
      start = 0
      depth = 0
      quote = nil
      escaped = false
      text.each_char.with_index do |character, index|
        if quote
          escaped = !escaped if character == "\\" && !escaped
          quote = nil if character == quote && !escaped
          escaped = false unless character == "\\"
        elsif ["'", '"'].include?(character)
          quote = character
        elsif "([{<".include?(character)
          depth += 1
        elsif ")]} >".delete(" ").include?(character)
          depth -= 1
        elsif character == "," && depth.zero?
          values << text[start...index]
          start = index + 1
        end
      end
      values << text[start..]
    end

    def format_parameter(parameter, sections)
      name = parameter[:name]
      return parameter[:source] unless name

      entry = sections.values.flatten(1).find { |candidate| candidate[0] == name }
      type = entry && entry[1]

      prefix = parameter[:source].start_with?("**") ? "**" : parameter[:source].start_with?("*") ? "*" : parameter[:source].start_with?("&") ? "&" : ""
      keyword = parameter[:source].include?(":") && !parameter[:source].include?("=>") ? ":" : ""
      parameter_name = "#{prefix}#{name}#{keyword}"
      return parameter_name unless type

      "#{normalize_type(type)} #{parameter_name}"
    end

    def return_type(sections)
      types = sections.fetch("Returns", []).filter_map(&:first).uniq
      return if types.empty?

      types.map { |type| normalize_type(type) }.join(" | ")
    end

    def normalize_type(type)
      type = type.to_s.strip
      type = type.gsub(/\A<|>\z/, "") if type.start_with?("<") && type.end_with?(">")
      return type if type.start_with?("#")

      type = type.gsub(/\bBoolean\b/, "bool")
      type = normalize_generic_types(type)
      split_top_level(type).map(&:strip).reject(&:empty?).join(" | ")
    end

    def normalize_generic_types(type)
      loop do
        changed = false
        protected_type = type.gsub("=>", "\0")
        protected_type = protected_type.gsub(/\b([A-Z][A-Za-z0-9_:]*)<([^<>]*)>/) do
          changed = true
          generic_name = Regexp.last_match(1)
          generic_contents = Regexp.last_match(2).gsub("\0", "=>")
          if generic_name == "Hash"
            hash_contents = generic_contents.split("=>", 2).map(&:strip)
            hash_contents = split_top_level(generic_contents) if hash_contents.length == 1
            if hash_contents.length == 2
              "Hash[#{normalize_type(hash_contents[0])}, #{normalize_type(hash_contents[1])}]"
            else
              "Hash[#{normalize_type(generic_contents)}]"
            end
          else
            "#{generic_name}[#{normalize_type(generic_contents)}]"
          end
        end
        type = protected_type.gsub("\0", "=>")
        type = type.gsub(/\bHash\{([^{}]*)\}/) do
          changed = true
          generic_contents = Regexp.last_match(1)
          hash_contents = generic_contents.split("=>", 2).map(&:strip)
          hash_contents = split_top_level(generic_contents) if hash_contents.length == 1
          if hash_contents.length == 2
            "Hash[#{normalize_type(hash_contents[0])}, #{normalize_type(hash_contents[1])}]"
          else
            "Hash[#{normalize_type(generic_contents)}]"
          end
        end
        break unless changed
      end
      type
    end

    def add_signature(block, signature)
      return block unless signature

      indent = block.first[/\A\s*/]
      marker_index = block.index { |line| line.include?(":call-seq:") }
      if marker_index
        signature_index = marker_index + 1
        updated = block.dup
        if signature_index < updated.length && updated[signature_index].match?(/^\s*#\s+/)
          updated[signature_index] = "#{indent}#   #{signature}\n"
        else
          updated.insert(signature_index, "#{indent}#   #{signature}\n")
        end
        return updated
      end

      insertion = [
        "#{indent}#\n",
        "#{indent}# :call-seq:\n",
        "#{indent}#   #{signature}\n",
      ]
      block + insertion
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {root: Dir.pwd, write: false}
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/type_signatures.rb [options]"
    parser.on("--write", "Write RDoc call-seq signatures") { options[:write] = true }
    parser.on("--check", "Fail when a signature is missing") { options[:check] = true }
    parser.on("--root PATH", "Repository root") { |path| options[:root] = path }
  end.parse!

  results = GraphQLDocs::TypeSignatureMigrator.new(root: options[:root]).run(write: options[:write])
  results.select(&:last).each { |path, _changed| puts "convert: #{path}" }
  exit 1 if options[:check] && results.any?(&:last)
end
