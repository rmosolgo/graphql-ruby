<!DOCTYPE HTML>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    
      <title>GraphQL - </title>
    
    <link href="https://fonts.googleapis.com/css?family=Rubik:300,400" rel="stylesheet" />
    <link rel="stylesheet" href="/css/main.css">
    <link rel="icon" href="/graphql-ruby-icon.png">
  </head>
  <body>
    <div class="header">
      <div class="header-container">
        <div class="nav">
          <a href="/" class="img-link">
            <img src="/graphql-ruby.png" alt="GraphQL Ruby Logo" />
          </a>
          <a href="/getting_started">Get Started</a>
          <a href="/guides">Guides</a>
          <a href="/api-doc/1.10.10/">API</a>
          <a href="https://tinyletter.com/graphql-ruby">Newsletter</a>
          <a href="https://github.com/rmosolgo/graphql-ruby">Source Code</a>
          <a href="https://graphql.pro">Upgrade to Pro</a>
          <input
            class="search-input"
            onkeyup="GraphQLRubySearch.run(this)"
            type="text"
            placeholder="Search the docs..."
          />
        </div>
      </div>
      <div class="search-results-container">
        <div id="search-results">
        </div>
      </div>
    </div>
    <div class="container">
      var client = algoliasearch('8VO8708WUV', '1f3e2b6f6a503fa82efdec331fd9c55e');
var index = client.initIndex('prod_graphql_ruby');

var GraphQLRubySearch = {
  // Respond to a change event on `el` by:
  // - Searching the index
  // - Rendering the results
  run: function(el) {
    var searchTerm = el.value
    var searchResults = document.querySelector("#search-results")
    if (!searchTerm) {
      // If there's no search term, clear the results pane
      searchResults.innerHTML = ""
    } else {
      index.search({
        query: searchTerm,
        hitsPerPage: 8,
      }, function(err, content) {
        if (err) {
          console.error(err)
        }
        var results = content.hits
        // Clear the previous results
        searchResults.innerHTML = ""

        results.forEach(function(result) {
          // Create a wrapper hyperlink
          var container = document.createElement("a")
          container.className = "search-result"
          container.href = (result.rubydoc_url || result.url) + (result.anchor  ? "#" + result.anchor : "")

          // This helper will be used to accumulate text into the search-result
          function createSpan(text, className) {
            var txt = document.createElement("span")
            txt.className = className
            txt.innerHTML = text
            container.appendChild(txt)
          }
          if (result.rubydoc_url) {
            createSpan("API Doc", "search-category")
            createSpan(result.title, "search-title")
          } else {
            createSpan(result.section, "search-category")

            var resultHeader = [result.title].concat(result.headings).join(" > ")
            createSpan(resultHeader, "search-title")
            var preview = result._snippetResult.content.value
            createSpan(preview, "search-preview")
          }
          searchResults.appendChild(container)
        })

        var seeAll = document.createElement("a")
        seeAll.href = "/search?query=" + content.query
        seeAll.className = "search-see-all"
        seeAll.innerHTML = "See All Results (" + content.nbHits + ")"
        searchResults.appendChild(seeAll)
      })
    }
  },

  // Return true if we actually highlighted something
  _moveHighlight: function(diff) {
    var allResults = document.querySelectorAll(".search-result")
    var highlightClass = "highlight-search-result"
    if (!allResults.length) {
      // No search results to highlight
      return false
    }
    var highlightedResult = document.querySelector("." + highlightClass)
    var nextHighlightedResult
    var result
    for (var i = 0; i < allResults.length; i++) {
      result = allResults[i]
      if (result == highlightedResult) {
        nextHighlightedResult = allResults[i + diff]
        break
      }
    }
    if (!nextHighlightedResult) {
      // Either nothing was highlighted yet,
      // or we were at the end of results and we loop around
      nextHighlightedResult = allResults[0]
    }

    if (highlightedResult) {
      highlightedResult.classList.remove(highlightClass)
    }
    nextHighlightedResult.classList.add(highlightClass)
    nextHighlightedResult.focus()
    return true
  }
}

document.addEventListener("keydown", function(ev) {
  var diff = ev.keyCode == 38 ? -1 : (ev.keyCode == 40 ? 1 : 0)
  if (diff) {
    var highlighted = GraphQLRubySearch._moveHighlight(diff)
    if (highlighted) {
      ev.preventDefault()
    }
  }
})

    </div>
    <script src="https://cdn.jsdelivr.net/algoliasearch/3/algoliasearchLite.min.js"></script>
    <script src="/js/search.js"></script>
  </body>
</html>
