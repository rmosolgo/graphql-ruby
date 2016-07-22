require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

class CodeHighlightHTML < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet # yep, that's it.
end

HighlightedMarkdownParser = Redcarpet::Markdown.new(CodeHighlightHTML, {
  fenced_code_blocks: true,
  autolink: true,
})

class HighlightedMarkdown < Nanoc::Filter
  identifier :highlighted_markdown
  type :text
  def run(content, params={})
    HighlightedMarkdownParser.render(content)
  end
end
