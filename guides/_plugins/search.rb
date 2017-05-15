module Jekyll
  class SearchTag < Liquid::Tag
    # required for strip_html:
    include Liquid::StandardFilters

    # @return [Hash] with array of pages & search index for them
    def render(context)
      pages = context.registers[:site].pages
      baseurl = context.registers[:site].baseurl
      # This will be an array of pages, indexed by `search_tree`
      page_data = []
      search_tree = build_search_tree

      pages
        .select { |page|
          # skip non-guide pages and skip blank guides (like the graphql-pro homepage)
          page.data["layout"] == "guide" && page.output
        }
        .each_with_index do |page, page_idx|
          # Remove header and breadcrumbs
          guide_content = page.output.match(/<div class="guide-container">(.*)<\/div>/m)[1]
          # Remove HTML and extraneous whitespace
          stripped_content = strip_html(guide_content).gsub(/\s+/, " ")
          # Metadata for showing the preview and adding a hyperlink:
          page_data << {
            path: baseurl + page.url,
            content: stripped_content,
            title: page.data["title"],
          }

          # Case-insensitive search, all lowercase
          normalized_content = stripped_content.downcase
          scanner = StringScanner.new(normalized_content)
          # Skip whitespace, only process words
          while scanner.skip_until(/\w+/)
            word = scanner.matched
            # skip words less than 4 characters long
            if word.length < 4
              next
            end
            word_idx = scanner.charpos - word.length
            # The index of the page in the pages array,
            # plus the index of the starting character of this word:
            index_entry = [page_idx, word_idx]
            t = search_tree
            # Add the word to the search tree, one character at a time
            word.each_char do |chr|
              t = t[chr]
              t[:pages] << index_entry
            end
          end
        end

      {
        pages: page_data,
        search: search_tree,
      }.to_json
    end

    private

    # A hash where:
    # - each key is a letter
    # - each value is another hash of letters
    #
    # But, the children hashes also have an array of "pages",
    # with pointers to the occurrence of that word, if there are any
    def build_search_tree
      Hash.new { |h, k|
        inner_tree = build_search_tree
        inner_tree[:pages] = []
        h[k] = inner_tree
      }
    end
  end
end

Liquid::Template.register_tag('search_data', Jekyll::SearchTag)
