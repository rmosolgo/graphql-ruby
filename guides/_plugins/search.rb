# frozen_string_literal: true
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
        .select { |page| page.data["search"] }
        .each_with_index do |page, page_idx|
          # Remove header and breadcrumbs
          if !page.output
            puts "Failed to index: #{page.data}"
            next
          end
          guide_match = page.output.match(/<div class="guide-container">(.*)<\/div>/m)
          if guide_match
            guide_content = guide_match[1]
          else
            guide_content = page.output
          end
          # Remove HTML and extraneous whitespace
          stripped_content = strip_html(guide_content).gsub(/\s+/, " ")
          # Metadata for showing the preview and adding a hyperlink:
          path = page.data["url"] || (baseurl + page.url)
          page_data << {
            path: path,
            content: stripped_content,
            title: page.data["title"],
          }

          # Case-insensitive search, all lowercase
          normalized_content = stripped_content.downcase
          scanner = StringScanner.new(normalized_content)
          # Skip whitespace, only process words
          while scanner.skip_until(/\w+/)
            word = scanner.matched
            if STOP_WORDS.include?(word)
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

    # From https://dev.mysql.com/doc/refman/5.5/en/fulltext-stopwords.html
    # rubocop:disable Style/WordArray
    STOP_WORDS = Set.new(%W(
      a's	able	about	above	according
      accordingly	across	actually	after	afterwards
      again	against	ain't	all	allow
      allows	almost	alone	along	already
      also	although	always	am	among
      amongst	an	and	another	any
      anybody	anyhow	anyone	anything	anyway
      anyways	anywhere	apart	appear	appreciate
      appropriate	are	aren't	around	as
      aside	ask	asking	associated	at
      available	away	awfully	be	became
      because	become	becomes	becoming	been
      before	beforehand	behind	being	believe
      below	beside	besides	best	better
      between	beyond	both	brief	but
      by	c'mon	c's	came	can
      can't	cannot	cant	cause	causes
      certain	certainly	changes	clearly	co
      com	come	comes	concerning	consequently
      consider	considering	contain	containing	contains
      corresponding	could	couldn't	course	currently
      definitely	described	despite	did	didn't
      different	do	does	doesn't	doing
      don't	done	down	downwards	during
      each	edu	eg	eight	either
      else	elsewhere	enough	entirely	especially
      et	etc	even	ever	every
      everybody	everyone	everything	everywhere	ex
      exactly	example	except	far	few
      fifth	first	five	followed	following
      follows	for	former	formerly	forth
      four	from	further	furthermore	get
      gets	getting	given	gives	go
      goes	going	gone	got	gotten
      greetings	had	hadn't	happens	hardly
      has	hasn't	have	haven't	having
      he	he's	hello	help	hence
      her	here	here's	hereafter	hereby
      herein	hereupon	hers	herself	hi
      him	himself	his	hither	hopefully
      how	howbeit	however	i'd	i'll
      i'm	i've	ie	if	ignored
      immediate	in	inasmuch	inc	indeed
      indicate	indicated	indicates	inner	insofar
      instead	into	inward	is	isn't
      it	it'd	it'll	it's	its
      itself	just	keep	keeps	kept
      know	known	knows	last	lately
      later	latter	latterly	least	less
      lest	let	let's	like	liked
      likely	little	look	looking	looks
      ltd	mainly	many	may	maybe
      me	mean	meanwhile	merely	might
      more	moreover	most	mostly	much
      must	my	myself	name	namely
      nd	near	nearly	necessary	need
      needs	neither	never	nevertheless	new
      next	nine	no	nobody	non
      none	noone	nor	normally	not
      nothing	novel	now	nowhere	obviously
      of	off	often	oh	ok
      okay	old	on	once	one
      ones	only	onto	or	other
      others	otherwise	ought	our	ours
      ourselves	out	outside	over	overall
      own	particular	particularly	per	perhaps
      placed	please	plus	possible	presumably
      probably	provides	que	quite	qv
      rather	rd	re	really	reasonably
      regarding	regardless	regards	relatively	respectively
      right	said	same	saw	say
      saying	says	second	secondly	see
      seeing	seem	seemed	seeming	seems
      seen	self	selves	sensible	sent
      serious	seriously	seven	several	shall
      she	should	shouldn't	since	six
      so	some	somebody	somehow	someone
      something	sometime	sometimes	somewhat	somewhere
      soon	sorry	specified	specify	specifying
      still	sub	such	sup	sure
      t's	take	taken	tell	tends
      th	than	thank	thanks	thanx
      that	that's	thats	the	their
      theirs	them	themselves	then	thence
      there	there's	thereafter	thereby	therefore
      therein	theres	thereupon	these	they
      they'd	they'll	they're	they've	think
      third	this	thorough	thoroughly	those
      though	three	through	throughout	thru
      thus	to	together	too	took
      toward	towards	tried	tries	truly
      try	trying	twice	two	un
      under	unfortunately	unless	unlikely	until
      unto	up	upon	us	use
      used	useful	uses	using	usually
      value	various	very	via	viz
      vs	want	wants	was	wasn't
      way	we	we'd	we'll	we're
      we've	welcome	well	went	were
      weren't	what	what's	whatever	when
      whence	whenever	where	where's	whereafter
      whereas	whereby	wherein	whereupon	wherever
      whether	which	while	whither	who
      who's	whoever	whole	whom	whose
      why	will	willing	wish	with
      within	without	won't	wonder	would
      wouldn't	yes	yet	you	you'd
      you'll	you're	you've	your	yours
      yourself	yourselves	zero
      ))
      # rubocop:enable Style/WordArray
  end
end

Liquid::Template.register_tag('search_data', Jekyll::SearchTag)
