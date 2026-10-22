'use strict';

/* graphql-ruby: graphql highlighter */
(function(root) {
  const KEYWORDS = new Set(['query', 'mutation', 'subscription', 'fragment', 'on', 'schema', 'type', 'interface', 'union', 'enum', 'input', 'scalar', 'directive', 'extend', 'implements']);
  const LITERALS = new Set(['true', 'false', 'null']);

  function escapeHTML(value) {
    return value.replace(/[&<>"']/g, (character) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    })[character]);
  }

  function span(className, value) {
    return `<span class="graphql-${className}">${escapeHTML(value)}</span>`;
  }

  function highlightGraphQL(source) {
    let html = '';
    let index = 0;
    while (index < source.length) {
      const rest = source.slice(index);
      let match;
      if (rest.startsWith('"""')) {
        const end = source.indexOf('"""', index + 3);
        const finish = end < 0 ? source.length : end + 3;
        html += span('string', source.slice(index, finish));
        index = finish;
      } else if (source[index] === '"') {
        match = source.slice(index).match(/^"(?:\\.|[^"\\])*"/s);
        const value = match ? match[0] : source.slice(index);
        html += span('string', value);
        index += value.length;
      } else if (source[index] === '#') {
        const end = source.indexOf('\n', index);
        const finish = end < 0 ? source.length : end;
        html += span('comment', source.slice(index, finish));
        index = finish;
      } else if ((match = rest.match(/^\$[_A-Za-z][_0-9A-Za-z]*/))) {
        html += span('variable', match[0]);
        index += match[0].length;
      } else if ((match = rest.match(/^@[_A-Za-z][_0-9A-Za-z]*/))) {
        html += span('directive', match[0]);
        index += match[0].length;
      } else if ((match = rest.match(/^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/))) {
        html += span('number', match[0]);
        index += match[0].length;
      } else if ((match = rest.match(/^[_A-Za-z][_0-9A-Za-z]*/))) {
        const value = match[0];
        html += span(KEYWORDS.has(value) ? 'keyword' : (LITERALS.has(value) ? 'literal' : 'name'), value);
        index += value.length;
      } else if ((match = rest.match(/^[!$():=@\[\]{|}&]/))) {
        html += span('punctuation', match[0]);
        index += 1;
      } else {
        html += escapeHTML(source[index]);
        index += 1;
      }
    }
    return html;
  }

  function highlightGraphQLDocument(document) {
    document.querySelectorAll('pre.graphql').forEach((element) => {
      if (element.dataset.graphqlHighlighted === 'true') return;
      const source = element.textContent;
      element.innerHTML = highlightGraphQL(source);
      element.dataset.graphqlHighlighted = 'true';
    });
  }

  root.GraphQLRubyHighlighter = { escapeHTML, highlightGraphQL, highlightGraphQLDocument };
  if (root.document) root.document.addEventListener('DOMContentLoaded', () => highlightGraphQLDocument(root.document));
  if (typeof module !== 'undefined') module.exports = root.GraphQLRubyHighlighter;
}(typeof globalThis === 'undefined' ? this : globalThis));
