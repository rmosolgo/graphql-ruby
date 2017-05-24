---
layout: null
---
var GraphQLRubySearch = {
  // Search the index for `searchStr`,
  // return an array of entries with the page data and matching text.
  search: function(searchTerm) {
    return this._loadIndex().then(function(idx) {
      // Normalize case
      var searchStr = searchTerm.toLowerCase()
      var search = idx.search
      var char
      // Only use the first word on the index, so split off the rest:
      var idxStr = searchStr.split(/\W/)[0]
      // For each character, step into a node of the index.
      // If the node isn't found, return `[]`, because the word isn't present anywhere.
      for(var i = 0; i < idxStr.length; i++) {
        char = idxStr.charAt(i)
        search = search[char]
        if(!search) {
          // Index miss
          return []
        }
      }
      var wordLen = searchStr.length
      var matches = {}

      if (!search.pages) {
        // A search with no leading word characters will 😢
        return []
      }

      search.pages.forEach(function(pagePos) {
        var pageIdx = pagePos[0]
        var page = idx.pages[pageIdx]
        var wordIdx = pagePos[1]
        var matchedText = page.content.substr(wordIdx, wordLen)
        // Make another check to handle multi-word searches,
        // this will rule out hits that don't match on later words.
        if (matchedText.toLowerCase() !== searchStr) {
          return
        }
        var match = matches[pageIdx]
        if (!match) {
          match = matches[pageIdx] = {
            page: page,
            matches: [],
          }
        }
        match.matches.push(wordIdx)
      })

      // After grouping the matches, apply a crude ranking:
      // the article with the most hits goes up, no tiebreakers.
      var orderedMatches = []
      var key, match, i, prevMatch
      for (key in matches) {
        match = matches[key]
        i = 0
        while ((prevMatch = orderedMatches[i]) && prevMatch.matches.length > match.matches.length) {
          i ++
        }
        orderedMatches.splice(i, 0, match)
      }
      return orderedMatches
    })
  },

  // Respond to a change event on `el` by:
  // - Searching the index
  // - Rendering the results
  run: function(el) {
    var searchTerm = el.value
    if (!searchTerm) {
      // If there's no search term, clear the results pane
      var searchResults = document.querySelector("#search-results")
      searchResults.innerHTML = ""
    } else {
      this.search(searchTerm).then(function(results) {
        var searchResults = document.querySelector("#search-results")
        // Clear the previous results
        searchResults.innerHTML = ""

        results.forEach(function(result) {
          var content = result.page.content
          // Create a wrapper hyperlink
          var container = document.createElement("a")
          container.href = result.page.path
          container.className = "search-result"

          // This helper will be used to accumulate text into the search-result
          function createSpan(text, className) {
            var txt = document.createElement("span")
            txt.className = className
            txt.innerHTML = text
            container.appendChild(txt)
          }
          // Add the title of the guide
          createSpan(result.page.title, "search-title")
          // Now, group matches by proximity
          var prevMatch, nextMatch
          var previewGroup = []
          var previewLength = 120
          var previewLead = 30
          var previewTail = 50
          var idx, previewBegin, previewIntroLength, shouldFlush
          // Use the fourth hit to render whatever we've found
          var maxHits = 4
          for(var i = 0; i <= maxHits; i ++) {
            nextMatch = result.matches[i]
            shouldFlush = (
              prevMatch && (
                !nextMatch || // There are no more matches
                (nextMatch - prevMatch > previewLength) || // The next match is too far
                i === maxHits // We're about to be done
              )
            )
            if (shouldFlush) {
              // We're outside the bounds of an overlapping preview,
              // so render what's here
              idx = previewGroup[0]
              if (idx < previewLead) {
                previewBegin = 0
                previewIntroLength = idx
              } else {
                previewBegin = idx - previewLead
                previewIntroLength = previewLead
              }
              // Lead-in:
              createSpan("…", "search-prefix")
              createSpan(content.substr(previewBegin, previewIntroLength), "search-prefix")

              // Each match:
              previewGroup.forEach(function(matchIdx, idx) {
                createSpan(content.substr(matchIdx, searchTerm.length), "search-match")
                var afterMatchIdx = matchIdx + searchTerm.length
                var tailLength
                if (idx < previewGroup.length - 1) {
                  tailLength = previewGroup[idx + 1] - afterMatchIdx
                } else {
                  tailLength = previewTail
                }
                createSpan(content.substr(afterMatchIdx, tailLength), "search-prefix")
              })

              // The old preview was rendered, start a new one:
              previewGroup = []
            }
            if (nextMatch) {
              previewGroup.push(nextMatch)
            }
            prevMatch = nextMatch
          }

          // Tail out:
          createSpan("…", "search-prefix")
          searchResults.appendChild(container)
        })
      })
    }
  },

  // The precompiled search index:
  _indexPath: "{{ site.baseurl }}/zz_search.json",

  // Store the index here after loading it once:
  _index: null,

  // Load the search index from cache or fetch from the server. Requires `fetch`.
  _loadIndex: function() {
    var indexPromise
    if (this._index) {
      indexPromise = Promise.resolve(this._index)
    } else {
      var _this = this
      indexPromise = fetch(this._indexPath)
        .then(function(response) { return response.json() })
        .then(function(index) {
          _this._index = index
          return index
        })
    }
    return indexPromise
  },
}
