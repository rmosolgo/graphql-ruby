'use strict';

const assert = require('node:assert/strict');
const { highlightGraphQL } = require('./graphql_highlighter.js');

const source = `query GetUser($id: ID!) {
  user(id: $id) @skip(if: false) {
    name
    bio # a comment
    note(text: "# is not a comment")
  }
}`;
const html = highlightGraphQL(source);
assert.match(html, /graphql-keyword/);
assert.match(html, /graphql-variable/);
assert.match(html, /graphql-directive/);
assert.match(html, /graphql-literal/);
assert.match(html, /graphql-comment/);
assert.match(html, /graphql-string/);
assert.doesNotMatch(html, /graphql-comment[^>]*>[^<]*# is not a comment/);
const escaped = highlightGraphQL('<script>alert("x")</script>');
assert.match(escaped, /&lt;/);
assert.doesNotMatch(escaped, /<script>/);
console.log('GraphQL highlighter tests passed');
