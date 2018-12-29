require 'pathname'

# Taken from https://github.com/jekyll/jekyll/issues/6360#issuecomment-329275101

module Jekyll
  module UrlRelativizer
    def relativize_url(url)
      pageUrl = @context.registers[:page]["url"]
      pageDir = Pathname(pageUrl).parent
      Pathname(url).relative_path_from(pageDir).to_s
    end
  end
end

Liquid::Template.register_filter(Jekyll::UrlRelativizer)
