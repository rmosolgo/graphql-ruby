(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports, require('apollo-link')) :
  typeof define === 'function' && define.amd ? define(['exports', 'apollo-link'], factory) :
  (global = global || self, factory(global['graphql-ruby-client-subscriptions'] = {}, global.apolloLink));
}(this, function (exports, apolloLink) { 'use strict';

  function _typeof(obj) {
    if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") {
      _typeof = function (obj) {
        return typeof obj;
      };
    } else {
      _typeof = function (obj) {
        return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
      };
    }

    return _typeof(obj);
  }

  function _classCallCheck(instance, Constructor) {
    if (!(instance instanceof Constructor)) {
      throw new TypeError("Cannot call a class as a function");
    }
  }

  function _defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  function _createClass(Constructor, protoProps, staticProps) {
    if (protoProps) _defineProperties(Constructor.prototype, protoProps);
    if (staticProps) _defineProperties(Constructor, staticProps);
    return Constructor;
  }

  function _inherits(subClass, superClass) {
    if (typeof superClass !== "function" && superClass !== null) {
      throw new TypeError("Super expression must either be null or a function");
    }

    subClass.prototype = Object.create(superClass && superClass.prototype, {
      constructor: {
        value: subClass,
        writable: true,
        configurable: true
      }
    });
    if (superClass) _setPrototypeOf(subClass, superClass);
  }

  function _getPrototypeOf(o) {
    _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
      return o.__proto__ || Object.getPrototypeOf(o);
    };
    return _getPrototypeOf(o);
  }

  function _setPrototypeOf(o, p) {
    _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
      o.__proto__ = p;
      return o;
    };

    return _setPrototypeOf(o, p);
  }

  function _assertThisInitialized(self) {
    if (self === void 0) {
      throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
    }

    return self;
  }

  function _possibleConstructorReturn(self, call) {
    if (call && (typeof call === "object" || typeof call === "function")) {
      return call;
    }

    return _assertThisInitialized(self);
  }

  var AblyLink =
  /*#__PURE__*/
  function (_ApolloLink) {
    _inherits(AblyLink, _ApolloLink);

    function AblyLink(options) {
      var _this;

      _classCallCheck(this, AblyLink);

      _this = _possibleConstructorReturn(this, _getPrototypeOf(AblyLink).call(this)); // Retain a handle to the Ably client

      _this.ably = options.ably;
      return _this;
    }

    _createClass(AblyLink, [{
      key: "request",
      value: function request(operation, forward) {
        var _this2 = this;

        return new apolloLink.Observable(function (observer) {
          // Check the result of the operation
          forward(operation).subscribe({
            next: function next(data) {
              // If the operation has the subscription header, it's a subscription
              var subscriptionChannel = _this2._getSubscriptionChannel(operation);

              if (subscriptionChannel) {
                // This will keep pushing to `.next`
                _this2._createSubscription(subscriptionChannel, observer);
              } else {
                // This isn't a subscription,
                // So pass the data along and close the observer.
                observer.next(data);
                observer.complete();
              }
            }
          });
        });
      }
    }, {
      key: "_getSubscriptionChannel",
      value: function _getSubscriptionChannel(operation) {
        var response = operation.getContext().response; // Check to see if the response has the header

        var subscriptionChannel = response.headers.get("X-Subscription-ID");
        return subscriptionChannel;
      }
    }, {
      key: "_createSubscription",
      value: function _createSubscription(subscriptionChannel, observer) {
        var ablyChannel = this.ably.channels.get(subscriptionChannel); // Register presence, so that we can detect empty channels and clean them up server-side

        ablyChannel.presence.enterClient("graphql-subscriber", "subscribed"); // Subscribe for more update

        ablyChannel.subscribe("update", function (message) {
          var payload = message.data;

          if (!payload.more) {
            // This is the end, the server says to unsubscribe
            ablyChannel.presence.leaveClient();
            ablyChannel.unsubscribe();
            observer.complete();
          }

          var result = payload.result;

          if (result) {
            // Send the new response to listeners
            observer.next(result);
          }
        });
      }
    }]);

    return AblyLink;
  }(apolloLink.ApolloLink);

  function unwrapExports (x) {
  	return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, 'default') ? x.default : x;
  }

  function createCommonjsModule(fn, module) {
  	return module = { exports: {} }, fn(module, module.exports), module.exports;
  }

  var location_1 = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.getLocation = getLocation;


  /**
   * Takes a Source and a UTF-8 character offset, and returns the corresponding
   * line and column as a SourceLocation.
   */

  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */

  function getLocation(source, position) {
    var lineRegexp = /\r\n|[\n\r]/g;
    var line = 1;
    var column = position + 1;
    var match = void 0;
    while ((match = lineRegexp.exec(source.body)) && match.index < position) {
      line += 1;
      column = position + 1 - (match.index + match[0].length);
    }
    return { line: line, column: column };
  }

  /**
   * Represents a location in a Source.
   */
  });

  unwrapExports(location_1);
  var location_2 = location_1.getLocation;

  var GraphQLError_1 = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.GraphQLError = GraphQLError;



  /**
   * A GraphQLError describes an Error found during the parse, validate, or
   * execute phases of performing a GraphQL operation. In addition to a message
   * and stack trace, it also includes information about the locations in a
   * GraphQL document and/or execution result that correspond to the Error.
   */
  function GraphQLError( // eslint-disable-line no-redeclare
  message, nodes, source, positions, path, originalError) {
    // Compute locations in the source for the given nodes/positions.
    var _source = source;
    if (!_source && nodes && nodes.length > 0) {
      var node = nodes[0];
      _source = node && node.loc && node.loc.source;
    }

    var _positions = positions;
    if (!_positions && nodes) {
      _positions = nodes.filter(function (node) {
        return Boolean(node.loc);
      }).map(function (node) {
        return node.loc.start;
      });
    }
    if (_positions && _positions.length === 0) {
      _positions = undefined;
    }

    var _locations = void 0;
    var _source2 = _source; // seems here Flow need a const to resolve type.
    if (_source2 && _positions) {
      _locations = _positions.map(function (pos) {
        return (0, location_1.getLocation)(_source2, pos);
      });
    }

    Object.defineProperties(this, {
      message: {
        value: message,
        // By being enumerable, JSON.stringify will include `message` in the
        // resulting output. This ensures that the simplest possible GraphQL
        // service adheres to the spec.
        enumerable: true,
        writable: true
      },
      locations: {
        // Coercing falsey values to undefined ensures they will not be included
        // in JSON.stringify() when not provided.
        value: _locations || undefined,
        // By being enumerable, JSON.stringify will include `locations` in the
        // resulting output. This ensures that the simplest possible GraphQL
        // service adheres to the spec.
        enumerable: true
      },
      path: {
        // Coercing falsey values to undefined ensures they will not be included
        // in JSON.stringify() when not provided.
        value: path || undefined,
        // By being enumerable, JSON.stringify will include `path` in the
        // resulting output. This ensures that the simplest possible GraphQL
        // service adheres to the spec.
        enumerable: true
      },
      nodes: {
        value: nodes || undefined
      },
      source: {
        value: _source || undefined
      },
      positions: {
        value: _positions || undefined
      },
      originalError: {
        value: originalError
      }
    });

    // Include (non-enumerable) stack trace.
    if (originalError && originalError.stack) {
      Object.defineProperty(this, 'stack', {
        value: originalError.stack,
        writable: true,
        configurable: true
      });
    } else if (Error.captureStackTrace) {
      Error.captureStackTrace(this, GraphQLError);
    } else {
      Object.defineProperty(this, 'stack', {
        value: Error().stack,
        writable: true,
        configurable: true
      });
    }
  }
  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */

  GraphQLError.prototype = Object.create(Error.prototype, {
    constructor: { value: GraphQLError },
    name: { value: 'GraphQLError' }
  });
  });

  unwrapExports(GraphQLError_1);
  var GraphQLError_2 = GraphQLError_1.GraphQLError;

  var syntaxError_1 = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.syntaxError = syntaxError;





  /**
   * Produces a GraphQLError representing a syntax error, containing useful
   * descriptive information about the syntax error's position in the source.
   */

  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */

  function syntaxError(source, position, description) {
    var location = (0, location_1.getLocation)(source, position);
    var line = location.line + source.locationOffset.line - 1;
    var columnOffset = getColumnOffset(source, location);
    var column = location.column + columnOffset;
    var error = new GraphQLError_1.GraphQLError('Syntax Error ' + source.name + ' (' + line + ':' + column + ') ' + description + '\n\n' + highlightSourceAtLocation(source, location), undefined, source, [position]);
    return error;
  }

  /**
   * Render a helpful description of the location of the error in the GraphQL
   * Source document.
   */
  function highlightSourceAtLocation(source, location) {
    var line = location.line;
    var lineOffset = source.locationOffset.line - 1;
    var columnOffset = getColumnOffset(source, location);
    var contextLine = line + lineOffset;
    var prevLineNum = (contextLine - 1).toString();
    var lineNum = contextLine.toString();
    var nextLineNum = (contextLine + 1).toString();
    var padLen = nextLineNum.length;
    var lines = source.body.split(/\r\n|[\n\r]/g);
    lines[0] = whitespace(source.locationOffset.column - 1) + lines[0];
    return (line >= 2 ? lpad(padLen, prevLineNum) + ': ' + lines[line - 2] + '\n' : '') + lpad(padLen, lineNum) + ': ' + lines[line - 1] + '\n' + whitespace(2 + padLen + location.column - 1 + columnOffset) + '^\n' + (line < lines.length ? lpad(padLen, nextLineNum) + ': ' + lines[line] + '\n' : '');
  }

  function getColumnOffset(source, location) {
    return location.line === 1 ? source.locationOffset.column - 1 : 0;
  }

  function whitespace(len) {
    return Array(len + 1).join(' ');
  }

  function lpad(len, str) {
    return whitespace(len - str.length) + str;
  }
  });

  unwrapExports(syntaxError_1);
  var syntaxError_2 = syntaxError_1.syntaxError;

  var locatedError_1 = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.locatedError = locatedError;



  /**
   * Given an arbitrary Error, presumably thrown while attempting to execute a
   * GraphQL operation, produce a new GraphQLError aware of the location in the
   * document responsible for the original Error.
   */
  function locatedError(originalError, nodes, path) {
    // Note: this uses a brand-check to support GraphQL errors originating from
    // other contexts.
    if (originalError && originalError.path) {
      return originalError;
    }

    var message = originalError ? originalError.message || String(originalError) : 'An unknown error occurred.';
    return new GraphQLError_1.GraphQLError(message, originalError && originalError.nodes || nodes, originalError && originalError.source, originalError && originalError.positions, path, originalError);
  }
  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */
  });

  unwrapExports(locatedError_1);
  var locatedError_2 = locatedError_1.locatedError;

  var invariant_1 = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.default = invariant;

  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */

  function invariant(condition, message) {
    if (!condition) {
      throw new Error(message);
    }
  }
  });

  unwrapExports(invariant_1);

  var formatError_1 = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.formatError = formatError;



  var _invariant2 = _interopRequireDefault(invariant_1);

  function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

  /**
   * Given a GraphQLError, format it according to the rules described by the
   * Response Format, Errors section of the GraphQL Specification.
   */
  function formatError(error) {
    !error ? (0, _invariant2.default)(0, 'Received null or undefined error.') : void 0;
    return {
      message: error.message,
      locations: error.locations,
      path: error.path
    };
  }
  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */
  });

  unwrapExports(formatError_1);
  var formatError_2 = formatError_1.formatError;

  var error = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });



  Object.defineProperty(exports, 'GraphQLError', {
    enumerable: true,
    get: function get() {
      return GraphQLError_1.GraphQLError;
    }
  });



  Object.defineProperty(exports, 'syntaxError', {
    enumerable: true,
    get: function get() {
      return syntaxError_1.syntaxError;
    }
  });



  Object.defineProperty(exports, 'locatedError', {
    enumerable: true,
    get: function get() {
      return locatedError_1.locatedError;
    }
  });



  Object.defineProperty(exports, 'formatError', {
    enumerable: true,
    get: function get() {
      return formatError_1.formatError;
    }
  });
  });

  unwrapExports(error);

  var lexer = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.TokenKind = undefined;
  exports.createLexer = createLexer;
  exports.getTokenDesc = getTokenDesc;



  /**
   * Given a Source object, this returns a Lexer for that source.
   * A Lexer is a stateful stream generator in that every time
   * it is advanced, it returns the next token in the Source. Assuming the
   * source lexes, the final Token emitted by the lexer will be of kind
   * EOF, after which the lexer will repeatedly return the same EOF token
   * whenever called.
   */
  function createLexer(source, options) {
    var startOfFileToken = new Tok(SOF, 0, 0, 0, 0, null);
    var lexer = {
      source: source,
      options: options,
      lastToken: startOfFileToken,
      token: startOfFileToken,
      line: 1,
      lineStart: 0,
      advance: advanceLexer
    };
    return lexer;
  } /*  /
    /**
     *  Copyright (c) 2015, Facebook, Inc.
     *  All rights reserved.
     *
     *  This source code is licensed under the BSD-style license found in the
     *  LICENSE file in the root directory of this source tree. An additional grant
     *  of patent rights can be found in the PATENTS file in the same directory.
     */

  function advanceLexer() {
    var token = this.lastToken = this.token;
    if (token.kind !== EOF) {
      do {
        token = token.next = readToken(this, token);
      } while (token.kind === COMMENT);
      this.token = token;
    }
    return token;
  }

  /**
   * The return type of createLexer.
   */


  // Each kind of token.
  var SOF = '<SOF>';
  var EOF = '<EOF>';
  var BANG = '!';
  var DOLLAR = '$';
  var PAREN_L = '(';
  var PAREN_R = ')';
  var SPREAD = '...';
  var COLON = ':';
  var EQUALS = '=';
  var AT = '@';
  var BRACKET_L = '[';
  var BRACKET_R = ']';
  var BRACE_L = '{';
  var PIPE = '|';
  var BRACE_R = '}';
  var NAME = 'Name';
  var INT = 'Int';
  var FLOAT = 'Float';
  var STRING = 'String';
  var COMMENT = 'Comment';

  /**
   * An exported enum describing the different kinds of tokens that the
   * lexer emits.
   */
  var TokenKind = exports.TokenKind = {
    SOF: SOF,
    EOF: EOF,
    BANG: BANG,
    DOLLAR: DOLLAR,
    PAREN_L: PAREN_L,
    PAREN_R: PAREN_R,
    SPREAD: SPREAD,
    COLON: COLON,
    EQUALS: EQUALS,
    AT: AT,
    BRACKET_L: BRACKET_L,
    BRACKET_R: BRACKET_R,
    BRACE_L: BRACE_L,
    PIPE: PIPE,
    BRACE_R: BRACE_R,
    NAME: NAME,
    INT: INT,
    FLOAT: FLOAT,
    STRING: STRING,
    COMMENT: COMMENT
  };

  /**
   * A helper function to describe a token as a string for debugging
   */
  function getTokenDesc(token) {
    var value = token.value;
    return value ? token.kind + ' "' + value + '"' : token.kind;
  }

  var charCodeAt = String.prototype.charCodeAt;
  var slice = String.prototype.slice;

  /**
   * Helper function for constructing the Token object.
   */
  function Tok(kind, start, end, line, column, prev, value) {
    this.kind = kind;
    this.start = start;
    this.end = end;
    this.line = line;
    this.column = column;
    this.value = value;
    this.prev = prev;
    this.next = null;
  }

  // Print a simplified form when appearing in JSON/util.inspect.
  Tok.prototype.toJSON = Tok.prototype.inspect = function toJSON() {
    return {
      kind: this.kind,
      value: this.value,
      line: this.line,
      column: this.column
    };
  };

  function printCharCode(code) {
    return (
      // NaN/undefined represents access beyond the end of the file.
      isNaN(code) ? EOF :
      // Trust JSON for ASCII.
      code < 0x007F ? JSON.stringify(String.fromCharCode(code)) :
      // Otherwise print the escaped form.
      '"\\u' + ('00' + code.toString(16).toUpperCase()).slice(-4) + '"'
    );
  }

  /**
   * Gets the next token from the source starting at the given position.
   *
   * This skips over whitespace and comments until it finds the next lexable
   * token, then lexes punctuators immediately or calls the appropriate helper
   * function for more complicated tokens.
   */
  function readToken(lexer, prev) {
    var source = lexer.source;
    var body = source.body;
    var bodyLength = body.length;

    var position = positionAfterWhitespace(body, prev.end, lexer);
    var line = lexer.line;
    var col = 1 + position - lexer.lineStart;

    if (position >= bodyLength) {
      return new Tok(EOF, bodyLength, bodyLength, line, col, prev);
    }

    var code = charCodeAt.call(body, position);

    // SourceCharacter
    if (code < 0x0020 && code !== 0x0009 && code !== 0x000A && code !== 0x000D) {
      throw (0, error.syntaxError)(source, position, 'Cannot contain the invalid character ' + printCharCode(code) + '.');
    }

    switch (code) {
      // !
      case 33:
        return new Tok(BANG, position, position + 1, line, col, prev);
      // #
      case 35:
        return readComment(source, position, line, col, prev);
      // $
      case 36:
        return new Tok(DOLLAR, position, position + 1, line, col, prev);
      // (
      case 40:
        return new Tok(PAREN_L, position, position + 1, line, col, prev);
      // )
      case 41:
        return new Tok(PAREN_R, position, position + 1, line, col, prev);
      // .
      case 46:
        if (charCodeAt.call(body, position + 1) === 46 && charCodeAt.call(body, position + 2) === 46) {
          return new Tok(SPREAD, position, position + 3, line, col, prev);
        }
        break;
      // :
      case 58:
        return new Tok(COLON, position, position + 1, line, col, prev);
      // =
      case 61:
        return new Tok(EQUALS, position, position + 1, line, col, prev);
      // @
      case 64:
        return new Tok(AT, position, position + 1, line, col, prev);
      // [
      case 91:
        return new Tok(BRACKET_L, position, position + 1, line, col, prev);
      // ]
      case 93:
        return new Tok(BRACKET_R, position, position + 1, line, col, prev);
      // {
      case 123:
        return new Tok(BRACE_L, position, position + 1, line, col, prev);
      // |
      case 124:
        return new Tok(PIPE, position, position + 1, line, col, prev);
      // }
      case 125:
        return new Tok(BRACE_R, position, position + 1, line, col, prev);
      // A-Z _ a-z
      case 65:case 66:case 67:case 68:case 69:case 70:case 71:case 72:
      case 73:case 74:case 75:case 76:case 77:case 78:case 79:case 80:
      case 81:case 82:case 83:case 84:case 85:case 86:case 87:case 88:
      case 89:case 90:
      case 95:
      case 97:case 98:case 99:case 100:case 101:case 102:case 103:case 104:
      case 105:case 106:case 107:case 108:case 109:case 110:case 111:
      case 112:case 113:case 114:case 115:case 116:case 117:case 118:
      case 119:case 120:case 121:case 122:
        return readName(source, position, line, col, prev);
      // - 0-9
      case 45:
      case 48:case 49:case 50:case 51:case 52:
      case 53:case 54:case 55:case 56:case 57:
        return readNumber(source, position, code, line, col, prev);
      // "
      case 34:
        return readString(source, position, line, col, prev);
    }

    throw (0, error.syntaxError)(source, position, unexpectedCharacterMessage(code));
  }

  /**
   * Report a message that an unexpected character was encountered.
   */
  function unexpectedCharacterMessage(code) {
    if (code === 39) {
      // '
      return 'Unexpected single quote character (\'), did you mean to use ' + 'a double quote (")?';
    }

    return 'Cannot parse the unexpected character ' + printCharCode(code) + '.';
  }

  /**
   * Reads from body starting at startPosition until it finds a non-whitespace
   * or commented character, then returns the position of that character for
   * lexing.
   */
  function positionAfterWhitespace(body, startPosition, lexer) {
    var bodyLength = body.length;
    var position = startPosition;
    while (position < bodyLength) {
      var code = charCodeAt.call(body, position);
      // tab | space | comma | BOM
      if (code === 9 || code === 32 || code === 44 || code === 0xFEFF) {
        ++position;
      } else if (code === 10) {
        // new line
        ++position;
        ++lexer.line;
        lexer.lineStart = position;
      } else if (code === 13) {
        // carriage return
        if (charCodeAt.call(body, position + 1) === 10) {
          position += 2;
        } else {
          ++position;
        }
        ++lexer.line;
        lexer.lineStart = position;
      } else {
        break;
      }
    }
    return position;
  }

  /**
   * Reads a comment token from the source file.
   *
   * #[\u0009\u0020-\uFFFF]*
   */
  function readComment(source, start, line, col, prev) {
    var body = source.body;
    var code = void 0;
    var position = start;

    do {
      code = charCodeAt.call(body, ++position);
    } while (code !== null && (
    // SourceCharacter but not LineTerminator
    code > 0x001F || code === 0x0009));

    return new Tok(COMMENT, start, position, line, col, prev, slice.call(body, start + 1, position));
  }

  /**
   * Reads a number token from the source file, either a float
   * or an int depending on whether a decimal point appears.
   *
   * Int:   -?(0|[1-9][0-9]*)
   * Float: -?(0|[1-9][0-9]*)(\.[0-9]+)?((E|e)(+|-)?[0-9]+)?
   */
  function readNumber(source, start, firstCode, line, col, prev) {
    var body = source.body;
    var code = firstCode;
    var position = start;
    var isFloat = false;

    if (code === 45) {
      // -
      code = charCodeAt.call(body, ++position);
    }

    if (code === 48) {
      // 0
      code = charCodeAt.call(body, ++position);
      if (code >= 48 && code <= 57) {
        throw (0, error.syntaxError)(source, position, 'Invalid number, unexpected digit after 0: ' + printCharCode(code) + '.');
      }
    } else {
      position = readDigits(source, position, code);
      code = charCodeAt.call(body, position);
    }

    if (code === 46) {
      // .
      isFloat = true;

      code = charCodeAt.call(body, ++position);
      position = readDigits(source, position, code);
      code = charCodeAt.call(body, position);
    }

    if (code === 69 || code === 101) {
      // E e
      isFloat = true;

      code = charCodeAt.call(body, ++position);
      if (code === 43 || code === 45) {
        // + -
        code = charCodeAt.call(body, ++position);
      }
      position = readDigits(source, position, code);
    }

    return new Tok(isFloat ? FLOAT : INT, start, position, line, col, prev, slice.call(body, start, position));
  }

  /**
   * Returns the new position in the source after reading digits.
   */
  function readDigits(source, start, firstCode) {
    var body = source.body;
    var position = start;
    var code = firstCode;
    if (code >= 48 && code <= 57) {
      // 0 - 9
      do {
        code = charCodeAt.call(body, ++position);
      } while (code >= 48 && code <= 57); // 0 - 9
      return position;
    }
    throw (0, error.syntaxError)(source, position, 'Invalid number, expected digit but got: ' + printCharCode(code) + '.');
  }

  /**
   * Reads a string token from the source file.
   *
   * "([^"\\\u000A\u000D]|(\\(u[0-9a-fA-F]{4}|["\\/bfnrt])))*"
   */
  function readString(source, start, line, col, prev) {
    var body = source.body;
    var position = start + 1;
    var chunkStart = position;
    var code = 0;
    var value = '';

    while (position < body.length && (code = charCodeAt.call(body, position)) !== null &&
    // not LineTerminator
    code !== 0x000A && code !== 0x000D &&
    // not Quote (")
    code !== 34) {
      // SourceCharacter
      if (code < 0x0020 && code !== 0x0009) {
        throw (0, error.syntaxError)(source, position, 'Invalid character within String: ' + printCharCode(code) + '.');
      }

      ++position;
      if (code === 92) {
        // \
        value += slice.call(body, chunkStart, position - 1);
        code = charCodeAt.call(body, position);
        switch (code) {
          case 34:
            value += '"';break;
          case 47:
            value += '/';break;
          case 92:
            value += '\\';break;
          case 98:
            value += '\b';break;
          case 102:
            value += '\f';break;
          case 110:
            value += '\n';break;
          case 114:
            value += '\r';break;
          case 116:
            value += '\t';break;
          case 117:
            // u
            var charCode = uniCharCode(charCodeAt.call(body, position + 1), charCodeAt.call(body, position + 2), charCodeAt.call(body, position + 3), charCodeAt.call(body, position + 4));
            if (charCode < 0) {
              throw (0, error.syntaxError)(source, position, 'Invalid character escape sequence: ' + ('\\u' + body.slice(position + 1, position + 5) + '.'));
            }
            value += String.fromCharCode(charCode);
            position += 4;
            break;
          default:
            throw (0, error.syntaxError)(source, position, 'Invalid character escape sequence: \\' + String.fromCharCode(code) + '.');
        }
        ++position;
        chunkStart = position;
      }
    }

    if (code !== 34) {
      // quote (")
      throw (0, error.syntaxError)(source, position, 'Unterminated string.');
    }

    value += slice.call(body, chunkStart, position);
    return new Tok(STRING, start, position + 1, line, col, prev, value);
  }

  /**
   * Converts four hexidecimal chars to the integer that the
   * string represents. For example, uniCharCode('0','0','0','f')
   * will return 15, and uniCharCode('0','0','f','f') returns 255.
   *
   * Returns a negative number on error, if a char was invalid.
   *
   * This is implemented by noting that char2hex() returns -1 on error,
   * which means the result of ORing the char2hex() will also be negative.
   */
  function uniCharCode(a, b, c, d) {
    return char2hex(a) << 12 | char2hex(b) << 8 | char2hex(c) << 4 | char2hex(d);
  }

  /**
   * Converts a hex character to its integer value.
   * '0' becomes 0, '9' becomes 9
   * 'A' becomes 10, 'F' becomes 15
   * 'a' becomes 10, 'f' becomes 15
   *
   * Returns -1 on error.
   */
  function char2hex(a) {
    return a >= 48 && a <= 57 ? a - 48 : // 0-9
    a >= 65 && a <= 70 ? a - 55 : // A-F
    a >= 97 && a <= 102 ? a - 87 : // a-f
    -1;
  }

  /**
   * Reads an alphanumeric + underscore name from the source.
   *
   * [_A-Za-z][_0-9A-Za-z]*
   */
  function readName(source, position, line, col, prev) {
    var body = source.body;
    var bodyLength = body.length;
    var end = position + 1;
    var code = 0;
    while (end !== bodyLength && (code = charCodeAt.call(body, end)) !== null && (code === 95 || // _
    code >= 48 && code <= 57 || // 0-9
    code >= 65 && code <= 90 || // A-Z
    code >= 97 && code <= 122 // a-z
    )) {
      ++end;
    }
    return new Tok(NAME, position, end, line, col, prev, slice.call(body, position, end));
  }
  });

  unwrapExports(lexer);
  var lexer_1 = lexer.TokenKind;
  var lexer_2 = lexer.createLexer;
  var lexer_3 = lexer.getTokenDesc;

  var source = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.Source = undefined;



  var _invariant2 = _interopRequireDefault(invariant_1);

  function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

  function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */

  /**
   * A representation of source input to GraphQL.
   * `name` and `locationOffset` are optional. They are useful for clients who
   * store GraphQL documents in source files; for example, if the GraphQL input
   * starts at line 40 in a file named Foo.graphql, it might be useful for name to
   * be "Foo.graphql" and location to be `{ line: 40, column: 0 }`.
   * line and column in locationOffset are 1-indexed
   */
  var Source = exports.Source = function Source(body, name, locationOffset) {
    _classCallCheck(this, Source);

    this.body = body;
    this.name = name || 'GraphQL request';
    this.locationOffset = locationOffset || { line: 1, column: 1 };
    !(this.locationOffset.line > 0) ? (0, _invariant2.default)(0, 'line in locationOffset is 1-indexed and must be positive') : void 0;
    !(this.locationOffset.column > 0) ? (0, _invariant2.default)(0, 'column in locationOffset is 1-indexed and must be positive') : void 0;
  };
  });

  unwrapExports(source);
  var source_1 = source.Source;

  var kinds = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */

  // Name

  var NAME = exports.NAME = 'Name';

  // Document

  var DOCUMENT = exports.DOCUMENT = 'Document';
  var OPERATION_DEFINITION = exports.OPERATION_DEFINITION = 'OperationDefinition';
  var VARIABLE_DEFINITION = exports.VARIABLE_DEFINITION = 'VariableDefinition';
  var VARIABLE = exports.VARIABLE = 'Variable';
  var SELECTION_SET = exports.SELECTION_SET = 'SelectionSet';
  var FIELD = exports.FIELD = 'Field';
  var ARGUMENT = exports.ARGUMENT = 'Argument';

  // Fragments

  var FRAGMENT_SPREAD = exports.FRAGMENT_SPREAD = 'FragmentSpread';
  var INLINE_FRAGMENT = exports.INLINE_FRAGMENT = 'InlineFragment';
  var FRAGMENT_DEFINITION = exports.FRAGMENT_DEFINITION = 'FragmentDefinition';

  // Values

  var INT = exports.INT = 'IntValue';
  var FLOAT = exports.FLOAT = 'FloatValue';
  var STRING = exports.STRING = 'StringValue';
  var BOOLEAN = exports.BOOLEAN = 'BooleanValue';
  var NULL = exports.NULL = 'NullValue';
  var ENUM = exports.ENUM = 'EnumValue';
  var LIST = exports.LIST = 'ListValue';
  var OBJECT = exports.OBJECT = 'ObjectValue';
  var OBJECT_FIELD = exports.OBJECT_FIELD = 'ObjectField';

  // Directives

  var DIRECTIVE = exports.DIRECTIVE = 'Directive';

  // Types

  var NAMED_TYPE = exports.NAMED_TYPE = 'NamedType';
  var LIST_TYPE = exports.LIST_TYPE = 'ListType';
  var NON_NULL_TYPE = exports.NON_NULL_TYPE = 'NonNullType';

  // Type System Definitions

  var SCHEMA_DEFINITION = exports.SCHEMA_DEFINITION = 'SchemaDefinition';
  var OPERATION_TYPE_DEFINITION = exports.OPERATION_TYPE_DEFINITION = 'OperationTypeDefinition';

  // Type Definitions

  var SCALAR_TYPE_DEFINITION = exports.SCALAR_TYPE_DEFINITION = 'ScalarTypeDefinition';
  var OBJECT_TYPE_DEFINITION = exports.OBJECT_TYPE_DEFINITION = 'ObjectTypeDefinition';
  var FIELD_DEFINITION = exports.FIELD_DEFINITION = 'FieldDefinition';
  var INPUT_VALUE_DEFINITION = exports.INPUT_VALUE_DEFINITION = 'InputValueDefinition';
  var INTERFACE_TYPE_DEFINITION = exports.INTERFACE_TYPE_DEFINITION = 'InterfaceTypeDefinition';
  var UNION_TYPE_DEFINITION = exports.UNION_TYPE_DEFINITION = 'UnionTypeDefinition';
  var ENUM_TYPE_DEFINITION = exports.ENUM_TYPE_DEFINITION = 'EnumTypeDefinition';
  var ENUM_VALUE_DEFINITION = exports.ENUM_VALUE_DEFINITION = 'EnumValueDefinition';
  var INPUT_OBJECT_TYPE_DEFINITION = exports.INPUT_OBJECT_TYPE_DEFINITION = 'InputObjectTypeDefinition';

  // Type Extensions

  var TYPE_EXTENSION_DEFINITION = exports.TYPE_EXTENSION_DEFINITION = 'TypeExtensionDefinition';

  // Directive Definitions

  var DIRECTIVE_DEFINITION = exports.DIRECTIVE_DEFINITION = 'DirectiveDefinition';
  });

  unwrapExports(kinds);
  var kinds_1 = kinds.NAME;
  var kinds_2 = kinds.DOCUMENT;
  var kinds_3 = kinds.OPERATION_DEFINITION;
  var kinds_4 = kinds.VARIABLE_DEFINITION;
  var kinds_5 = kinds.VARIABLE;
  var kinds_6 = kinds.SELECTION_SET;
  var kinds_7 = kinds.FIELD;
  var kinds_8 = kinds.ARGUMENT;
  var kinds_9 = kinds.FRAGMENT_SPREAD;
  var kinds_10 = kinds.INLINE_FRAGMENT;
  var kinds_11 = kinds.FRAGMENT_DEFINITION;
  var kinds_12 = kinds.INT;
  var kinds_13 = kinds.FLOAT;
  var kinds_14 = kinds.STRING;
  var kinds_15 = kinds.BOOLEAN;
  var kinds_16 = kinds.NULL;
  var kinds_17 = kinds.ENUM;
  var kinds_18 = kinds.LIST;
  var kinds_19 = kinds.OBJECT;
  var kinds_20 = kinds.OBJECT_FIELD;
  var kinds_21 = kinds.DIRECTIVE;
  var kinds_22 = kinds.NAMED_TYPE;
  var kinds_23 = kinds.LIST_TYPE;
  var kinds_24 = kinds.NON_NULL_TYPE;
  var kinds_25 = kinds.SCHEMA_DEFINITION;
  var kinds_26 = kinds.OPERATION_TYPE_DEFINITION;
  var kinds_27 = kinds.SCALAR_TYPE_DEFINITION;
  var kinds_28 = kinds.OBJECT_TYPE_DEFINITION;
  var kinds_29 = kinds.FIELD_DEFINITION;
  var kinds_30 = kinds.INPUT_VALUE_DEFINITION;
  var kinds_31 = kinds.INTERFACE_TYPE_DEFINITION;
  var kinds_32 = kinds.UNION_TYPE_DEFINITION;
  var kinds_33 = kinds.ENUM_TYPE_DEFINITION;
  var kinds_34 = kinds.ENUM_VALUE_DEFINITION;
  var kinds_35 = kinds.INPUT_OBJECT_TYPE_DEFINITION;
  var kinds_36 = kinds.TYPE_EXTENSION_DEFINITION;
  var kinds_37 = kinds.DIRECTIVE_DEFINITION;

  var parser = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.parse = parse;
  exports.parseValue = parseValue;
  exports.parseType = parseType;
  exports.parseConstValue = parseConstValue;
  exports.parseTypeReference = parseTypeReference;
  exports.parseNamedType = parseNamedType;









  /**
   * Given a GraphQL source, parses it into a Document.
   * Throws GraphQLError if a syntax error is encountered.
   */


  /**
   * Configuration options to control parser behavior
   */

  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */

  function parse(source$$1, options) {
    var sourceObj = typeof source$$1 === 'string' ? new source.Source(source$$1) : source$$1;
    if (!(sourceObj instanceof source.Source)) {
      throw new TypeError('Must provide Source. Received: ' + String(sourceObj));
    }
    var lexer$$1 = (0, lexer.createLexer)(sourceObj, options || {});
    return parseDocument(lexer$$1);
  }

  /**
   * Given a string containing a GraphQL value (ex. `[42]`), parse the AST for
   * that value.
   * Throws GraphQLError if a syntax error is encountered.
   *
   * This is useful within tools that operate upon GraphQL Values directly and
   * in isolation of complete GraphQL documents.
   *
   * Consider providing the results to the utility function: valueFromAST().
   */
  function parseValue(source$$1, options) {
    var sourceObj = typeof source$$1 === 'string' ? new source.Source(source$$1) : source$$1;
    var lexer$$1 = (0, lexer.createLexer)(sourceObj, options || {});
    expect(lexer$$1, lexer.TokenKind.SOF);
    var value = parseValueLiteral(lexer$$1, false);
    expect(lexer$$1, lexer.TokenKind.EOF);
    return value;
  }

  /**
   * Given a string containing a GraphQL Type (ex. `[Int!]`), parse the AST for
   * that type.
   * Throws GraphQLError if a syntax error is encountered.
   *
   * This is useful within tools that operate upon GraphQL Types directly and
   * in isolation of complete GraphQL documents.
   *
   * Consider providing the results to the utility function: typeFromAST().
   */
  function parseType(source$$1, options) {
    var sourceObj = typeof source$$1 === 'string' ? new source.Source(source$$1) : source$$1;
    var lexer$$1 = (0, lexer.createLexer)(sourceObj, options || {});
    expect(lexer$$1, lexer.TokenKind.SOF);
    var type = parseTypeReference(lexer$$1);
    expect(lexer$$1, lexer.TokenKind.EOF);
    return type;
  }

  /**
   * Converts a name lex token into a name parse node.
   */
  function parseName(lexer$$1) {
    var token = expect(lexer$$1, lexer.TokenKind.NAME);
    return {
      kind: kinds.NAME,
      value: token.value,
      loc: loc(lexer$$1, token)
    };
  }

  // Implements the parsing rules in the Document section.

  /**
   * Document : Definition+
   */
  function parseDocument(lexer$$1) {
    var start = lexer$$1.token;
    expect(lexer$$1, lexer.TokenKind.SOF);
    var definitions = [];
    do {
      definitions.push(parseDefinition(lexer$$1));
    } while (!skip(lexer$$1, lexer.TokenKind.EOF));

    return {
      kind: kinds.DOCUMENT,
      definitions: definitions,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * Definition :
   *   - OperationDefinition
   *   - FragmentDefinition
   *   - TypeSystemDefinition
   */
  function parseDefinition(lexer$$1) {
    if (peek(lexer$$1, lexer.TokenKind.BRACE_L)) {
      return parseOperationDefinition(lexer$$1);
    }

    if (peek(lexer$$1, lexer.TokenKind.NAME)) {
      switch (lexer$$1.token.value) {
        // Note: subscription is an experimental non-spec addition.
        case 'query':
        case 'mutation':
        case 'subscription':
          return parseOperationDefinition(lexer$$1);

        case 'fragment':
          return parseFragmentDefinition(lexer$$1);

        // Note: the Type System IDL is an experimental non-spec addition.
        case 'schema':
        case 'scalar':
        case 'type':
        case 'interface':
        case 'union':
        case 'enum':
        case 'input':
        case 'extend':
        case 'directive':
          return parseTypeSystemDefinition(lexer$$1);
      }
    }

    throw unexpected(lexer$$1);
  }

  // Implements the parsing rules in the Operations section.

  /**
   * OperationDefinition :
   *  - SelectionSet
   *  - OperationType Name? VariableDefinitions? Directives? SelectionSet
   */
  function parseOperationDefinition(lexer$$1) {
    var start = lexer$$1.token;
    if (peek(lexer$$1, lexer.TokenKind.BRACE_L)) {
      return {
        kind: kinds.OPERATION_DEFINITION,
        operation: 'query',
        name: null,
        variableDefinitions: null,
        directives: [],
        selectionSet: parseSelectionSet(lexer$$1),
        loc: loc(lexer$$1, start)
      };
    }
    var operation = parseOperationType(lexer$$1);
    var name = void 0;
    if (peek(lexer$$1, lexer.TokenKind.NAME)) {
      name = parseName(lexer$$1);
    }
    return {
      kind: kinds.OPERATION_DEFINITION,
      operation: operation,
      name: name,
      variableDefinitions: parseVariableDefinitions(lexer$$1),
      directives: parseDirectives(lexer$$1),
      selectionSet: parseSelectionSet(lexer$$1),
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * OperationType : one of query mutation subscription
   */
  function parseOperationType(lexer$$1) {
    var operationToken = expect(lexer$$1, lexer.TokenKind.NAME);
    switch (operationToken.value) {
      case 'query':
        return 'query';
      case 'mutation':
        return 'mutation';
      // Note: subscription is an experimental non-spec addition.
      case 'subscription':
        return 'subscription';
    }

    throw unexpected(lexer$$1, operationToken);
  }

  /**
   * VariableDefinitions : ( VariableDefinition+ )
   */
  function parseVariableDefinitions(lexer$$1) {
    return peek(lexer$$1, lexer.TokenKind.PAREN_L) ? many(lexer$$1, lexer.TokenKind.PAREN_L, parseVariableDefinition, lexer.TokenKind.PAREN_R) : [];
  }

  /**
   * VariableDefinition : Variable : Type DefaultValue?
   */
  function parseVariableDefinition(lexer$$1) {
    var start = lexer$$1.token;
    return {
      kind: kinds.VARIABLE_DEFINITION,
      variable: parseVariable(lexer$$1),
      type: (expect(lexer$$1, lexer.TokenKind.COLON), parseTypeReference(lexer$$1)),
      defaultValue: skip(lexer$$1, lexer.TokenKind.EQUALS) ? parseValueLiteral(lexer$$1, true) : null,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * Variable : $ Name
   */
  function parseVariable(lexer$$1) {
    var start = lexer$$1.token;
    expect(lexer$$1, lexer.TokenKind.DOLLAR);
    return {
      kind: kinds.VARIABLE,
      name: parseName(lexer$$1),
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * SelectionSet : { Selection+ }
   */
  function parseSelectionSet(lexer$$1) {
    var start = lexer$$1.token;
    return {
      kind: kinds.SELECTION_SET,
      selections: many(lexer$$1, lexer.TokenKind.BRACE_L, parseSelection, lexer.TokenKind.BRACE_R),
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * Selection :
   *   - Field
   *   - FragmentSpread
   *   - InlineFragment
   */
  function parseSelection(lexer$$1) {
    return peek(lexer$$1, lexer.TokenKind.SPREAD) ? parseFragment(lexer$$1) : parseField(lexer$$1);
  }

  /**
   * Field : Alias? Name Arguments? Directives? SelectionSet?
   *
   * Alias : Name :
   */
  function parseField(lexer$$1) {
    var start = lexer$$1.token;

    var nameOrAlias = parseName(lexer$$1);
    var alias = void 0;
    var name = void 0;
    if (skip(lexer$$1, lexer.TokenKind.COLON)) {
      alias = nameOrAlias;
      name = parseName(lexer$$1);
    } else {
      alias = null;
      name = nameOrAlias;
    }

    return {
      kind: kinds.FIELD,
      alias: alias,
      name: name,
      arguments: parseArguments(lexer$$1),
      directives: parseDirectives(lexer$$1),
      selectionSet: peek(lexer$$1, lexer.TokenKind.BRACE_L) ? parseSelectionSet(lexer$$1) : null,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * Arguments : ( Argument+ )
   */
  function parseArguments(lexer$$1) {
    return peek(lexer$$1, lexer.TokenKind.PAREN_L) ? many(lexer$$1, lexer.TokenKind.PAREN_L, parseArgument, lexer.TokenKind.PAREN_R) : [];
  }

  /**
   * Argument : Name : Value
   */
  function parseArgument(lexer$$1) {
    var start = lexer$$1.token;
    return {
      kind: kinds.ARGUMENT,
      name: parseName(lexer$$1),
      value: (expect(lexer$$1, lexer.TokenKind.COLON), parseValueLiteral(lexer$$1, false)),
      loc: loc(lexer$$1, start)
    };
  }

  // Implements the parsing rules in the Fragments section.

  /**
   * Corresponds to both FragmentSpread and InlineFragment in the spec.
   *
   * FragmentSpread : ... FragmentName Directives?
   *
   * InlineFragment : ... TypeCondition? Directives? SelectionSet
   */
  function parseFragment(lexer$$1) {
    var start = lexer$$1.token;
    expect(lexer$$1, lexer.TokenKind.SPREAD);
    if (peek(lexer$$1, lexer.TokenKind.NAME) && lexer$$1.token.value !== 'on') {
      return {
        kind: kinds.FRAGMENT_SPREAD,
        name: parseFragmentName(lexer$$1),
        directives: parseDirectives(lexer$$1),
        loc: loc(lexer$$1, start)
      };
    }
    var typeCondition = null;
    if (lexer$$1.token.value === 'on') {
      lexer$$1.advance();
      typeCondition = parseNamedType(lexer$$1);
    }
    return {
      kind: kinds.INLINE_FRAGMENT,
      typeCondition: typeCondition,
      directives: parseDirectives(lexer$$1),
      selectionSet: parseSelectionSet(lexer$$1),
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * FragmentDefinition :
   *   - fragment FragmentName on TypeCondition Directives? SelectionSet
   *
   * TypeCondition : NamedType
   */
  function parseFragmentDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'fragment');
    return {
      kind: kinds.FRAGMENT_DEFINITION,
      name: parseFragmentName(lexer$$1),
      typeCondition: (expectKeyword(lexer$$1, 'on'), parseNamedType(lexer$$1)),
      directives: parseDirectives(lexer$$1),
      selectionSet: parseSelectionSet(lexer$$1),
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * FragmentName : Name but not `on`
   */
  function parseFragmentName(lexer$$1) {
    if (lexer$$1.token.value === 'on') {
      throw unexpected(lexer$$1);
    }
    return parseName(lexer$$1);
  }

  // Implements the parsing rules in the Values section.

  /**
   * Value[Const] :
   *   - [~Const] Variable
   *   - IntValue
   *   - FloatValue
   *   - StringValue
   *   - BooleanValue
   *   - NullValue
   *   - EnumValue
   *   - ListValue[?Const]
   *   - ObjectValue[?Const]
   *
   * BooleanValue : one of `true` `false`
   *
   * NullValue : `null`
   *
   * EnumValue : Name but not `true`, `false` or `null`
   */
  function parseValueLiteral(lexer$$1, isConst) {
    var token = lexer$$1.token;
    switch (token.kind) {
      case lexer.TokenKind.BRACKET_L:
        return parseList(lexer$$1, isConst);
      case lexer.TokenKind.BRACE_L:
        return parseObject(lexer$$1, isConst);
      case lexer.TokenKind.INT:
        lexer$$1.advance();
        return {
          kind: kinds.INT,
          value: token.value,
          loc: loc(lexer$$1, token)
        };
      case lexer.TokenKind.FLOAT:
        lexer$$1.advance();
        return {
          kind: kinds.FLOAT,
          value: token.value,
          loc: loc(lexer$$1, token)
        };
      case lexer.TokenKind.STRING:
        lexer$$1.advance();
        return {
          kind: kinds.STRING,
          value: token.value,
          loc: loc(lexer$$1, token)
        };
      case lexer.TokenKind.NAME:
        if (token.value === 'true' || token.value === 'false') {
          lexer$$1.advance();
          return {
            kind: kinds.BOOLEAN,
            value: token.value === 'true',
            loc: loc(lexer$$1, token)
          };
        } else if (token.value === 'null') {
          lexer$$1.advance();
          return {
            kind: kinds.NULL,
            loc: loc(lexer$$1, token)
          };
        }
        lexer$$1.advance();
        return {
          kind: kinds.ENUM,
          value: token.value,
          loc: loc(lexer$$1, token)
        };
      case lexer.TokenKind.DOLLAR:
        if (!isConst) {
          return parseVariable(lexer$$1);
        }
        break;
    }
    throw unexpected(lexer$$1);
  }

  function parseConstValue(lexer$$1) {
    return parseValueLiteral(lexer$$1, true);
  }

  function parseValueValue(lexer$$1) {
    return parseValueLiteral(lexer$$1, false);
  }

  /**
   * ListValue[Const] :
   *   - [ ]
   *   - [ Value[?Const]+ ]
   */
  function parseList(lexer$$1, isConst) {
    var start = lexer$$1.token;
    var item = isConst ? parseConstValue : parseValueValue;
    return {
      kind: kinds.LIST,
      values: any(lexer$$1, lexer.TokenKind.BRACKET_L, item, lexer.TokenKind.BRACKET_R),
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * ObjectValue[Const] :
   *   - { }
   *   - { ObjectField[?Const]+ }
   */
  function parseObject(lexer$$1, isConst) {
    var start = lexer$$1.token;
    expect(lexer$$1, lexer.TokenKind.BRACE_L);
    var fields = [];
    while (!skip(lexer$$1, lexer.TokenKind.BRACE_R)) {
      fields.push(parseObjectField(lexer$$1, isConst));
    }
    return {
      kind: kinds.OBJECT,
      fields: fields,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * ObjectField[Const] : Name : Value[?Const]
   */
  function parseObjectField(lexer$$1, isConst) {
    var start = lexer$$1.token;
    return {
      kind: kinds.OBJECT_FIELD,
      name: parseName(lexer$$1),
      value: (expect(lexer$$1, lexer.TokenKind.COLON), parseValueLiteral(lexer$$1, isConst)),
      loc: loc(lexer$$1, start)
    };
  }

  // Implements the parsing rules in the Directives section.

  /**
   * Directives : Directive+
   */
  function parseDirectives(lexer$$1) {
    var directives = [];
    while (peek(lexer$$1, lexer.TokenKind.AT)) {
      directives.push(parseDirective(lexer$$1));
    }
    return directives;
  }

  /**
   * Directive : @ Name Arguments?
   */
  function parseDirective(lexer$$1) {
    var start = lexer$$1.token;
    expect(lexer$$1, lexer.TokenKind.AT);
    return {
      kind: kinds.DIRECTIVE,
      name: parseName(lexer$$1),
      arguments: parseArguments(lexer$$1),
      loc: loc(lexer$$1, start)
    };
  }

  // Implements the parsing rules in the Types section.

  /**
   * Type :
   *   - NamedType
   *   - ListType
   *   - NonNullType
   */
  function parseTypeReference(lexer$$1) {
    var start = lexer$$1.token;
    var type = void 0;
    if (skip(lexer$$1, lexer.TokenKind.BRACKET_L)) {
      type = parseTypeReference(lexer$$1);
      expect(lexer$$1, lexer.TokenKind.BRACKET_R);
      type = {
        kind: kinds.LIST_TYPE,
        type: type,
        loc: loc(lexer$$1, start)
      };
    } else {
      type = parseNamedType(lexer$$1);
    }
    if (skip(lexer$$1, lexer.TokenKind.BANG)) {
      return {
        kind: kinds.NON_NULL_TYPE,
        type: type,
        loc: loc(lexer$$1, start)
      };
    }
    return type;
  }

  /**
   * NamedType : Name
   */
  function parseNamedType(lexer$$1) {
    var start = lexer$$1.token;
    return {
      kind: kinds.NAMED_TYPE,
      name: parseName(lexer$$1),
      loc: loc(lexer$$1, start)
    };
  }

  // Implements the parsing rules in the Type Definition section.

  /**
   * TypeSystemDefinition :
   *   - SchemaDefinition
   *   - TypeDefinition
   *   - TypeExtensionDefinition
   *   - DirectiveDefinition
   *
   * TypeDefinition :
   *   - ScalarTypeDefinition
   *   - ObjectTypeDefinition
   *   - InterfaceTypeDefinition
   *   - UnionTypeDefinition
   *   - EnumTypeDefinition
   *   - InputObjectTypeDefinition
   */
  function parseTypeSystemDefinition(lexer$$1) {
    if (peek(lexer$$1, lexer.TokenKind.NAME)) {
      switch (lexer$$1.token.value) {
        case 'schema':
          return parseSchemaDefinition(lexer$$1);
        case 'scalar':
          return parseScalarTypeDefinition(lexer$$1);
        case 'type':
          return parseObjectTypeDefinition(lexer$$1);
        case 'interface':
          return parseInterfaceTypeDefinition(lexer$$1);
        case 'union':
          return parseUnionTypeDefinition(lexer$$1);
        case 'enum':
          return parseEnumTypeDefinition(lexer$$1);
        case 'input':
          return parseInputObjectTypeDefinition(lexer$$1);
        case 'extend':
          return parseTypeExtensionDefinition(lexer$$1);
        case 'directive':
          return parseDirectiveDefinition(lexer$$1);
      }
    }

    throw unexpected(lexer$$1);
  }

  /**
   * SchemaDefinition : schema Directives? { OperationTypeDefinition+ }
   *
   * OperationTypeDefinition : OperationType : NamedType
   */
  function parseSchemaDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'schema');
    var directives = parseDirectives(lexer$$1);
    var operationTypes = many(lexer$$1, lexer.TokenKind.BRACE_L, parseOperationTypeDefinition, lexer.TokenKind.BRACE_R);
    return {
      kind: kinds.SCHEMA_DEFINITION,
      directives: directives,
      operationTypes: operationTypes,
      loc: loc(lexer$$1, start)
    };
  }

  function parseOperationTypeDefinition(lexer$$1) {
    var start = lexer$$1.token;
    var operation = parseOperationType(lexer$$1);
    expect(lexer$$1, lexer.TokenKind.COLON);
    var type = parseNamedType(lexer$$1);
    return {
      kind: kinds.OPERATION_TYPE_DEFINITION,
      operation: operation,
      type: type,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * ScalarTypeDefinition : scalar Name Directives?
   */
  function parseScalarTypeDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'scalar');
    var name = parseName(lexer$$1);
    var directives = parseDirectives(lexer$$1);
    return {
      kind: kinds.SCALAR_TYPE_DEFINITION,
      name: name,
      directives: directives,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * ObjectTypeDefinition :
   *   - type Name ImplementsInterfaces? Directives? { FieldDefinition+ }
   */
  function parseObjectTypeDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'type');
    var name = parseName(lexer$$1);
    var interfaces = parseImplementsInterfaces(lexer$$1);
    var directives = parseDirectives(lexer$$1);
    var fields = any(lexer$$1, lexer.TokenKind.BRACE_L, parseFieldDefinition, lexer.TokenKind.BRACE_R);
    return {
      kind: kinds.OBJECT_TYPE_DEFINITION,
      name: name,
      interfaces: interfaces,
      directives: directives,
      fields: fields,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * ImplementsInterfaces : implements NamedType+
   */
  function parseImplementsInterfaces(lexer$$1) {
    var types = [];
    if (lexer$$1.token.value === 'implements') {
      lexer$$1.advance();
      do {
        types.push(parseNamedType(lexer$$1));
      } while (peek(lexer$$1, lexer.TokenKind.NAME));
    }
    return types;
  }

  /**
   * FieldDefinition : Name ArgumentsDefinition? : Type Directives?
   */
  function parseFieldDefinition(lexer$$1) {
    var start = lexer$$1.token;
    var name = parseName(lexer$$1);
    var args = parseArgumentDefs(lexer$$1);
    expect(lexer$$1, lexer.TokenKind.COLON);
    var type = parseTypeReference(lexer$$1);
    var directives = parseDirectives(lexer$$1);
    return {
      kind: kinds.FIELD_DEFINITION,
      name: name,
      arguments: args,
      type: type,
      directives: directives,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * ArgumentsDefinition : ( InputValueDefinition+ )
   */
  function parseArgumentDefs(lexer$$1) {
    if (!peek(lexer$$1, lexer.TokenKind.PAREN_L)) {
      return [];
    }
    return many(lexer$$1, lexer.TokenKind.PAREN_L, parseInputValueDef, lexer.TokenKind.PAREN_R);
  }

  /**
   * InputValueDefinition : Name : Type DefaultValue? Directives?
   */
  function parseInputValueDef(lexer$$1) {
    var start = lexer$$1.token;
    var name = parseName(lexer$$1);
    expect(lexer$$1, lexer.TokenKind.COLON);
    var type = parseTypeReference(lexer$$1);
    var defaultValue = null;
    if (skip(lexer$$1, lexer.TokenKind.EQUALS)) {
      defaultValue = parseConstValue(lexer$$1);
    }
    var directives = parseDirectives(lexer$$1);
    return {
      kind: kinds.INPUT_VALUE_DEFINITION,
      name: name,
      type: type,
      defaultValue: defaultValue,
      directives: directives,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * InterfaceTypeDefinition : interface Name Directives? { FieldDefinition+ }
   */
  function parseInterfaceTypeDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'interface');
    var name = parseName(lexer$$1);
    var directives = parseDirectives(lexer$$1);
    var fields = any(lexer$$1, lexer.TokenKind.BRACE_L, parseFieldDefinition, lexer.TokenKind.BRACE_R);
    return {
      kind: kinds.INTERFACE_TYPE_DEFINITION,
      name: name,
      directives: directives,
      fields: fields,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * UnionTypeDefinition : union Name Directives? = UnionMembers
   */
  function parseUnionTypeDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'union');
    var name = parseName(lexer$$1);
    var directives = parseDirectives(lexer$$1);
    expect(lexer$$1, lexer.TokenKind.EQUALS);
    var types = parseUnionMembers(lexer$$1);
    return {
      kind: kinds.UNION_TYPE_DEFINITION,
      name: name,
      directives: directives,
      types: types,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * UnionMembers :
   *   - `|`? NamedType
   *   - UnionMembers | NamedType
   */
  function parseUnionMembers(lexer$$1) {
    // Optional leading pipe
    skip(lexer$$1, lexer.TokenKind.PIPE);
    var members = [];
    do {
      members.push(parseNamedType(lexer$$1));
    } while (skip(lexer$$1, lexer.TokenKind.PIPE));
    return members;
  }

  /**
   * EnumTypeDefinition : enum Name Directives? { EnumValueDefinition+ }
   */
  function parseEnumTypeDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'enum');
    var name = parseName(lexer$$1);
    var directives = parseDirectives(lexer$$1);
    var values = many(lexer$$1, lexer.TokenKind.BRACE_L, parseEnumValueDefinition, lexer.TokenKind.BRACE_R);
    return {
      kind: kinds.ENUM_TYPE_DEFINITION,
      name: name,
      directives: directives,
      values: values,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * EnumValueDefinition : EnumValue Directives?
   *
   * EnumValue : Name
   */
  function parseEnumValueDefinition(lexer$$1) {
    var start = lexer$$1.token;
    var name = parseName(lexer$$1);
    var directives = parseDirectives(lexer$$1);
    return {
      kind: kinds.ENUM_VALUE_DEFINITION,
      name: name,
      directives: directives,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * InputObjectTypeDefinition : input Name Directives? { InputValueDefinition+ }
   */
  function parseInputObjectTypeDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'input');
    var name = parseName(lexer$$1);
    var directives = parseDirectives(lexer$$1);
    var fields = any(lexer$$1, lexer.TokenKind.BRACE_L, parseInputValueDef, lexer.TokenKind.BRACE_R);
    return {
      kind: kinds.INPUT_OBJECT_TYPE_DEFINITION,
      name: name,
      directives: directives,
      fields: fields,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * TypeExtensionDefinition : extend ObjectTypeDefinition
   */
  function parseTypeExtensionDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'extend');
    var definition = parseObjectTypeDefinition(lexer$$1);
    return {
      kind: kinds.TYPE_EXTENSION_DEFINITION,
      definition: definition,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * DirectiveDefinition :
   *   - directive @ Name ArgumentsDefinition? on DirectiveLocations
   */
  function parseDirectiveDefinition(lexer$$1) {
    var start = lexer$$1.token;
    expectKeyword(lexer$$1, 'directive');
    expect(lexer$$1, lexer.TokenKind.AT);
    var name = parseName(lexer$$1);
    var args = parseArgumentDefs(lexer$$1);
    expectKeyword(lexer$$1, 'on');
    var locations = parseDirectiveLocations(lexer$$1);
    return {
      kind: kinds.DIRECTIVE_DEFINITION,
      name: name,
      arguments: args,
      locations: locations,
      loc: loc(lexer$$1, start)
    };
  }

  /**
   * DirectiveLocations :
   *   - `|`? Name
   *   - DirectiveLocations | Name
   */
  function parseDirectiveLocations(lexer$$1) {
    // Optional leading pipe
    skip(lexer$$1, lexer.TokenKind.PIPE);
    var locations = [];
    do {
      locations.push(parseName(lexer$$1));
    } while (skip(lexer$$1, lexer.TokenKind.PIPE));
    return locations;
  }

  // Core parsing utility functions

  /**
   * Returns a location object, used to identify the place in
   * the source that created a given parsed object.
   */
  function loc(lexer$$1, startToken) {
    if (!lexer$$1.options.noLocation) {
      return new Loc(startToken, lexer$$1.lastToken, lexer$$1.source);
    }
  }

  function Loc(startToken, endToken, source$$1) {
    this.start = startToken.start;
    this.end = endToken.end;
    this.startToken = startToken;
    this.endToken = endToken;
    this.source = source$$1;
  }

  // Print a simplified form when appearing in JSON/util.inspect.
  Loc.prototype.toJSON = Loc.prototype.inspect = function toJSON() {
    return { start: this.start, end: this.end };
  };

  /**
   * Determines if the next token is of a given kind
   */
  function peek(lexer$$1, kind) {
    return lexer$$1.token.kind === kind;
  }

  /**
   * If the next token is of the given kind, return true after advancing
   * the lexer. Otherwise, do not change the parser state and return false.
   */
  function skip(lexer$$1, kind) {
    var match = lexer$$1.token.kind === kind;
    if (match) {
      lexer$$1.advance();
    }
    return match;
  }

  /**
   * If the next token is of the given kind, return that token after advancing
   * the lexer. Otherwise, do not change the parser state and throw an error.
   */
  function expect(lexer$$1, kind) {
    var token = lexer$$1.token;
    if (token.kind === kind) {
      lexer$$1.advance();
      return token;
    }
    throw (0, error.syntaxError)(lexer$$1.source, token.start, 'Expected ' + kind + ', found ' + (0, lexer.getTokenDesc)(token));
  }

  /**
   * If the next token is a keyword with the given value, return that token after
   * advancing the lexer. Otherwise, do not change the parser state and return
   * false.
   */
  function expectKeyword(lexer$$1, value) {
    var token = lexer$$1.token;
    if (token.kind === lexer.TokenKind.NAME && token.value === value) {
      lexer$$1.advance();
      return token;
    }
    throw (0, error.syntaxError)(lexer$$1.source, token.start, 'Expected "' + value + '", found ' + (0, lexer.getTokenDesc)(token));
  }

  /**
   * Helper function for creating an error when an unexpected lexed token
   * is encountered.
   */
  function unexpected(lexer$$1, atToken) {
    var token = atToken || lexer$$1.token;
    return (0, error.syntaxError)(lexer$$1.source, token.start, 'Unexpected ' + (0, lexer.getTokenDesc)(token));
  }

  /**
   * Returns a possibly empty list of parse nodes, determined by
   * the parseFn. This list begins with a lex token of openKind
   * and ends with a lex token of closeKind. Advances the parser
   * to the next lex token after the closing token.
   */
  function any(lexer$$1, openKind, parseFn, closeKind) {
    expect(lexer$$1, openKind);
    var nodes = [];
    while (!skip(lexer$$1, closeKind)) {
      nodes.push(parseFn(lexer$$1));
    }
    return nodes;
  }

  /**
   * Returns a non-empty list of parse nodes, determined by
   * the parseFn. This list begins with a lex token of openKind
   * and ends with a lex token of closeKind. Advances the parser
   * to the next lex token after the closing token.
   */
  function many(lexer$$1, openKind, parseFn, closeKind) {
    expect(lexer$$1, openKind);
    var nodes = [parseFn(lexer$$1)];
    while (!skip(lexer$$1, closeKind)) {
      nodes.push(parseFn(lexer$$1));
    }
    return nodes;
  }
  });

  unwrapExports(parser);
  var parser_1 = parser.parse;
  var parser_2 = parser.parseValue;
  var parser_3 = parser.parseType;
  var parser_4 = parser.parseConstValue;
  var parser_5 = parser.parseTypeReference;
  var parser_6 = parser.parseNamedType;

  var visitor = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.visit = visit;
  exports.visitInParallel = visitInParallel;
  exports.visitWithTypeInfo = visitWithTypeInfo;
  exports.getVisitFn = getVisitFn;
  /**
   *  Copyright (c) 2015, Facebook, Inc.
   *  All rights reserved.
   *
   *  This source code is licensed under the BSD-style license found in the
   *  LICENSE file in the root directory of this source tree. An additional grant
   *  of patent rights can be found in the PATENTS file in the same directory.
   */

  var QueryDocumentKeys = exports.QueryDocumentKeys = {
    Name: [],

    Document: ['definitions'],
    OperationDefinition: ['name', 'variableDefinitions', 'directives', 'selectionSet'],
    VariableDefinition: ['variable', 'type', 'defaultValue'],
    Variable: ['name'],
    SelectionSet: ['selections'],
    Field: ['alias', 'name', 'arguments', 'directives', 'selectionSet'],
    Argument: ['name', 'value'],

    FragmentSpread: ['name', 'directives'],
    InlineFragment: ['typeCondition', 'directives', 'selectionSet'],
    FragmentDefinition: ['name', 'typeCondition', 'directives', 'selectionSet'],

    IntValue: [],
    FloatValue: [],
    StringValue: [],
    BooleanValue: [],
    NullValue: [],
    EnumValue: [],
    ListValue: ['values'],
    ObjectValue: ['fields'],
    ObjectField: ['name', 'value'],

    Directive: ['name', 'arguments'],

    NamedType: ['name'],
    ListType: ['type'],
    NonNullType: ['type'],

    SchemaDefinition: ['directives', 'operationTypes'],
    OperationTypeDefinition: ['type'],

    ScalarTypeDefinition: ['name', 'directives'],
    ObjectTypeDefinition: ['name', 'interfaces', 'directives', 'fields'],
    FieldDefinition: ['name', 'arguments', 'type', 'directives'],
    InputValueDefinition: ['name', 'type', 'defaultValue', 'directives'],
    InterfaceTypeDefinition: ['name', 'directives', 'fields'],
    UnionTypeDefinition: ['name', 'directives', 'types'],
    EnumTypeDefinition: ['name', 'directives', 'values'],
    EnumValueDefinition: ['name', 'directives'],
    InputObjectTypeDefinition: ['name', 'directives', 'fields'],

    TypeExtensionDefinition: ['definition'],

    DirectiveDefinition: ['name', 'arguments', 'locations']
  };

  var BREAK = exports.BREAK = {};

  /**
   * visit() will walk through an AST using a depth first traversal, calling
   * the visitor's enter function at each node in the traversal, and calling the
   * leave function after visiting that node and all of its child nodes.
   *
   * By returning different values from the enter and leave functions, the
   * behavior of the visitor can be altered, including skipping over a sub-tree of
   * the AST (by returning false), editing the AST by returning a value or null
   * to remove the value, or to stop the whole traversal by returning BREAK.
   *
   * When using visit() to edit an AST, the original AST will not be modified, and
   * a new version of the AST with the changes applied will be returned from the
   * visit function.
   *
   *     const editedAST = visit(ast, {
   *       enter(node, key, parent, path, ancestors) {
   *         // @return
   *         //   undefined: no action
   *         //   false: skip visiting this node
   *         //   visitor.BREAK: stop visiting altogether
   *         //   null: delete this node
   *         //   any value: replace this node with the returned value
   *       },
   *       leave(node, key, parent, path, ancestors) {
   *         // @return
   *         //   undefined: no action
   *         //   false: no action
   *         //   visitor.BREAK: stop visiting altogether
   *         //   null: delete this node
   *         //   any value: replace this node with the returned value
   *       }
   *     });
   *
   * Alternatively to providing enter() and leave() functions, a visitor can
   * instead provide functions named the same as the kinds of AST nodes, or
   * enter/leave visitors at a named key, leading to four permutations of
   * visitor API:
   *
   * 1) Named visitors triggered when entering a node a specific kind.
   *
   *     visit(ast, {
   *       Kind(node) {
   *         // enter the "Kind" node
   *       }
   *     })
   *
   * 2) Named visitors that trigger upon entering and leaving a node of
   *    a specific kind.
   *
   *     visit(ast, {
   *       Kind: {
   *         enter(node) {
   *           // enter the "Kind" node
   *         }
   *         leave(node) {
   *           // leave the "Kind" node
   *         }
   *       }
   *     })
   *
   * 3) Generic visitors that trigger upon entering and leaving any node.
   *
   *     visit(ast, {
   *       enter(node) {
   *         // enter any node
   *       },
   *       leave(node) {
   *         // leave any node
   *       }
   *     })
   *
   * 4) Parallel visitors for entering and leaving nodes of a specific kind.
   *
   *     visit(ast, {
   *       enter: {
   *         Kind(node) {
   *           // enter the "Kind" node
   *         }
   *       },
   *       leave: {
   *         Kind(node) {
   *           // leave the "Kind" node
   *         }
   *       }
   *     })
   */
  function visit(root, visitor, keyMap) {
    var visitorKeys = keyMap || QueryDocumentKeys;

    var stack = void 0;
    var inArray = Array.isArray(root);
    var keys = [root];
    var index = -1;
    var edits = [];
    var parent = void 0;
    var path = [];
    var ancestors = [];
    var newRoot = root;

    do {
      index++;
      var isLeaving = index === keys.length;
      var key = void 0;
      var node = void 0;
      var isEdited = isLeaving && edits.length !== 0;
      if (isLeaving) {
        key = ancestors.length === 0 ? undefined : path.pop();
        node = parent;
        parent = ancestors.pop();
        if (isEdited) {
          if (inArray) {
            node = node.slice();
          } else {
            var clone = {};
            for (var k in node) {
              if (node.hasOwnProperty(k)) {
                clone[k] = node[k];
              }
            }
            node = clone;
          }
          var editOffset = 0;
          for (var ii = 0; ii < edits.length; ii++) {
            var editKey = edits[ii][0];
            var editValue = edits[ii][1];
            if (inArray) {
              editKey -= editOffset;
            }
            if (inArray && editValue === null) {
              node.splice(editKey, 1);
              editOffset++;
            } else {
              node[editKey] = editValue;
            }
          }
        }
        index = stack.index;
        keys = stack.keys;
        edits = stack.edits;
        inArray = stack.inArray;
        stack = stack.prev;
      } else {
        key = parent ? inArray ? index : keys[index] : undefined;
        node = parent ? parent[key] : newRoot;
        if (node === null || node === undefined) {
          continue;
        }
        if (parent) {
          path.push(key);
        }
      }

      var result = void 0;
      if (!Array.isArray(node)) {
        if (!isNode(node)) {
          throw new Error('Invalid AST Node: ' + JSON.stringify(node));
        }
        var visitFn = getVisitFn(visitor, node.kind, isLeaving);
        if (visitFn) {
          result = visitFn.call(visitor, node, key, parent, path, ancestors);

          if (result === BREAK) {
            break;
          }

          if (result === false) {
            if (!isLeaving) {
              path.pop();
              continue;
            }
          } else if (result !== undefined) {
            edits.push([key, result]);
            if (!isLeaving) {
              if (isNode(result)) {
                node = result;
              } else {
                path.pop();
                continue;
              }
            }
          }
        }
      }

      if (result === undefined && isEdited) {
        edits.push([key, node]);
      }

      if (!isLeaving) {
        stack = { inArray: inArray, index: index, keys: keys, edits: edits, prev: stack };
        inArray = Array.isArray(node);
        keys = inArray ? node : visitorKeys[node.kind] || [];
        index = -1;
        edits = [];
        if (parent) {
          ancestors.push(parent);
        }
        parent = node;
      }
    } while (stack !== undefined);

    if (edits.length !== 0) {
      newRoot = edits[edits.length - 1][1];
    }

    return newRoot;
  }

  function isNode(maybeNode) {
    return maybeNode && typeof maybeNode.kind === 'string';
  }

  /**
   * Creates a new visitor instance which delegates to many visitors to run in
   * parallel. Each visitor will be visited for each node before moving on.
   *
   * If a prior visitor edits a node, no following visitors will see that node.
   */
  function visitInParallel(visitors) {
    var skipping = new Array(visitors.length);

    return {
      enter: function enter(node) {
        for (var i = 0; i < visitors.length; i++) {
          if (!skipping[i]) {
            var fn = getVisitFn(visitors[i], node.kind, /* isLeaving */false);
            if (fn) {
              var result = fn.apply(visitors[i], arguments);
              if (result === false) {
                skipping[i] = node;
              } else if (result === BREAK) {
                skipping[i] = BREAK;
              } else if (result !== undefined) {
                return result;
              }
            }
          }
        }
      },
      leave: function leave(node) {
        for (var i = 0; i < visitors.length; i++) {
          if (!skipping[i]) {
            var fn = getVisitFn(visitors[i], node.kind, /* isLeaving */true);
            if (fn) {
              var result = fn.apply(visitors[i], arguments);
              if (result === BREAK) {
                skipping[i] = BREAK;
              } else if (result !== undefined && result !== false) {
                return result;
              }
            }
          } else if (skipping[i] === node) {
            skipping[i] = null;
          }
        }
      }
    };
  }

  /**
   * Creates a new visitor instance which maintains a provided TypeInfo instance
   * along with visiting visitor.
   */
  function visitWithTypeInfo(typeInfo, visitor) {
    return {
      enter: function enter(node) {
        typeInfo.enter(node);
        var fn = getVisitFn(visitor, node.kind, /* isLeaving */false);
        if (fn) {
          var result = fn.apply(visitor, arguments);
          if (result !== undefined) {
            typeInfo.leave(node);
            if (isNode(result)) {
              typeInfo.enter(result);
            }
          }
          return result;
        }
      },
      leave: function leave(node) {
        var fn = getVisitFn(visitor, node.kind, /* isLeaving */true);
        var result = void 0;
        if (fn) {
          result = fn.apply(visitor, arguments);
        }
        typeInfo.leave(node);
        return result;
      }
    };
  }

  /**
   * Given a visitor instance, if it is leaving or not, and a node kind, return
   * the function the visitor runtime should call.
   */
  function getVisitFn(visitor, kind, isLeaving) {
    var kindVisitor = visitor[kind];
    if (kindVisitor) {
      if (!isLeaving && typeof kindVisitor === 'function') {
        // { Kind() {} }
        return kindVisitor;
      }
      var kindSpecificVisitor = isLeaving ? kindVisitor.leave : kindVisitor.enter;
      if (typeof kindSpecificVisitor === 'function') {
        // { Kind: { enter() {}, leave() {} } }
        return kindSpecificVisitor;
      }
    } else {
      var specificVisitor = isLeaving ? visitor.leave : visitor.enter;
      if (specificVisitor) {
        if (typeof specificVisitor === 'function') {
          // { enter() {}, leave() {} }
          return specificVisitor;
        }
        var specificKindVisitor = specificVisitor[kind];
        if (typeof specificKindVisitor === 'function') {
          // { enter: { Kind() {} }, leave: { Kind() {} } }
          return specificKindVisitor;
        }
      }
    }
  }
  });

  unwrapExports(visitor);
  var visitor_1 = visitor.visit;
  var visitor_2 = visitor.visitInParallel;
  var visitor_3 = visitor.visitWithTypeInfo;
  var visitor_4 = visitor.getVisitFn;
  var visitor_5 = visitor.QueryDocumentKeys;
  var visitor_6 = visitor.BREAK;

  var printer = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.print = print;



  /**
   * Converts an AST into a string, using one set of reasonable
   * formatting rules.
   */
  function print(ast) {
    return (0, visitor.visit)(ast, { leave: printDocASTReducer });
  } /**
     *  Copyright (c) 2015, Facebook, Inc.
     *  All rights reserved.
     *
     *  This source code is licensed under the BSD-style license found in the
     *  LICENSE file in the root directory of this source tree. An additional grant
     *  of patent rights can be found in the PATENTS file in the same directory.
     */

  var printDocASTReducer = {
    Name: function Name(node) {
      return node.value;
    },
    Variable: function Variable(node) {
      return '$' + node.name;
    },

    // Document

    Document: function Document(node) {
      return join(node.definitions, '\n\n') + '\n';
    },

    OperationDefinition: function OperationDefinition(node) {
      var op = node.operation;
      var name = node.name;
      var varDefs = wrap('(', join(node.variableDefinitions, ', '), ')');
      var directives = join(node.directives, ' ');
      var selectionSet = node.selectionSet;
      // Anonymous queries with no directives or variable definitions can use
      // the query short form.
      return !name && !directives && !varDefs && op === 'query' ? selectionSet : join([op, join([name, varDefs]), directives, selectionSet], ' ');
    },


    VariableDefinition: function VariableDefinition(_ref) {
      var variable = _ref.variable,
          type = _ref.type,
          defaultValue = _ref.defaultValue;
      return variable + ': ' + type + wrap(' = ', defaultValue);
    },

    SelectionSet: function SelectionSet(_ref2) {
      var selections = _ref2.selections;
      return block(selections);
    },

    Field: function Field(_ref3) {
      var alias = _ref3.alias,
          name = _ref3.name,
          args = _ref3.arguments,
          directives = _ref3.directives,
          selectionSet = _ref3.selectionSet;
      return join([wrap('', alias, ': ') + name + wrap('(', join(args, ', '), ')'), join(directives, ' '), selectionSet], ' ');
    },

    Argument: function Argument(_ref4) {
      var name = _ref4.name,
          value = _ref4.value;
      return name + ': ' + value;
    },

    // Fragments

    FragmentSpread: function FragmentSpread(_ref5) {
      var name = _ref5.name,
          directives = _ref5.directives;
      return '...' + name + wrap(' ', join(directives, ' '));
    },

    InlineFragment: function InlineFragment(_ref6) {
      var typeCondition = _ref6.typeCondition,
          directives = _ref6.directives,
          selectionSet = _ref6.selectionSet;
      return join(['...', wrap('on ', typeCondition), join(directives, ' '), selectionSet], ' ');
    },

    FragmentDefinition: function FragmentDefinition(_ref7) {
      var name = _ref7.name,
          typeCondition = _ref7.typeCondition,
          directives = _ref7.directives,
          selectionSet = _ref7.selectionSet;
      return 'fragment ' + name + ' on ' + typeCondition + ' ' + wrap('', join(directives, ' '), ' ') + selectionSet;
    },

    // Value

    IntValue: function IntValue(_ref8) {
      var value = _ref8.value;
      return value;
    },
    FloatValue: function FloatValue(_ref9) {
      var value = _ref9.value;
      return value;
    },
    StringValue: function StringValue(_ref10) {
      var value = _ref10.value;
      return JSON.stringify(value);
    },
    BooleanValue: function BooleanValue(_ref11) {
      var value = _ref11.value;
      return JSON.stringify(value);
    },
    NullValue: function NullValue() {
      return 'null';
    },
    EnumValue: function EnumValue(_ref12) {
      var value = _ref12.value;
      return value;
    },
    ListValue: function ListValue(_ref13) {
      var values = _ref13.values;
      return '[' + join(values, ', ') + ']';
    },
    ObjectValue: function ObjectValue(_ref14) {
      var fields = _ref14.fields;
      return '{' + join(fields, ', ') + '}';
    },
    ObjectField: function ObjectField(_ref15) {
      var name = _ref15.name,
          value = _ref15.value;
      return name + ': ' + value;
    },

    // Directive

    Directive: function Directive(_ref16) {
      var name = _ref16.name,
          args = _ref16.arguments;
      return '@' + name + wrap('(', join(args, ', '), ')');
    },

    // Type

    NamedType: function NamedType(_ref17) {
      var name = _ref17.name;
      return name;
    },
    ListType: function ListType(_ref18) {
      var type = _ref18.type;
      return '[' + type + ']';
    },
    NonNullType: function NonNullType(_ref19) {
      var type = _ref19.type;
      return type + '!';
    },

    // Type System Definitions

    SchemaDefinition: function SchemaDefinition(_ref20) {
      var directives = _ref20.directives,
          operationTypes = _ref20.operationTypes;
      return join(['schema', join(directives, ' '), block(operationTypes)], ' ');
    },

    OperationTypeDefinition: function OperationTypeDefinition(_ref21) {
      var operation = _ref21.operation,
          type = _ref21.type;
      return operation + ': ' + type;
    },

    ScalarTypeDefinition: function ScalarTypeDefinition(_ref22) {
      var name = _ref22.name,
          directives = _ref22.directives;
      return join(['scalar', name, join(directives, ' ')], ' ');
    },

    ObjectTypeDefinition: function ObjectTypeDefinition(_ref23) {
      var name = _ref23.name,
          interfaces = _ref23.interfaces,
          directives = _ref23.directives,
          fields = _ref23.fields;
      return join(['type', name, wrap('implements ', join(interfaces, ', ')), join(directives, ' '), block(fields)], ' ');
    },

    FieldDefinition: function FieldDefinition(_ref24) {
      var name = _ref24.name,
          args = _ref24.arguments,
          type = _ref24.type,
          directives = _ref24.directives;
      return name + wrap('(', join(args, ', '), ')') + ': ' + type + wrap(' ', join(directives, ' '));
    },

    InputValueDefinition: function InputValueDefinition(_ref25) {
      var name = _ref25.name,
          type = _ref25.type,
          defaultValue = _ref25.defaultValue,
          directives = _ref25.directives;
      return join([name + ': ' + type, wrap('= ', defaultValue), join(directives, ' ')], ' ');
    },

    InterfaceTypeDefinition: function InterfaceTypeDefinition(_ref26) {
      var name = _ref26.name,
          directives = _ref26.directives,
          fields = _ref26.fields;
      return join(['interface', name, join(directives, ' '), block(fields)], ' ');
    },

    UnionTypeDefinition: function UnionTypeDefinition(_ref27) {
      var name = _ref27.name,
          directives = _ref27.directives,
          types = _ref27.types;
      return join(['union', name, join(directives, ' '), '= ' + join(types, ' | ')], ' ');
    },

    EnumTypeDefinition: function EnumTypeDefinition(_ref28) {
      var name = _ref28.name,
          directives = _ref28.directives,
          values = _ref28.values;
      return join(['enum', name, join(directives, ' '), block(values)], ' ');
    },

    EnumValueDefinition: function EnumValueDefinition(_ref29) {
      var name = _ref29.name,
          directives = _ref29.directives;
      return join([name, join(directives, ' ')], ' ');
    },

    InputObjectTypeDefinition: function InputObjectTypeDefinition(_ref30) {
      var name = _ref30.name,
          directives = _ref30.directives,
          fields = _ref30.fields;
      return join(['input', name, join(directives, ' '), block(fields)], ' ');
    },

    TypeExtensionDefinition: function TypeExtensionDefinition(_ref31) {
      var definition = _ref31.definition;
      return 'extend ' + definition;
    },

    DirectiveDefinition: function DirectiveDefinition(_ref32) {
      var name = _ref32.name,
          args = _ref32.arguments,
          locations = _ref32.locations;
      return 'directive @' + name + wrap('(', join(args, ', '), ')') + ' on ' + join(locations, ' | ');
    }
  };

  /**
   * Given maybeArray, print an empty string if it is null or empty, otherwise
   * print all items together separated by separator if provided
   */
  function join(maybeArray, separator) {
    return maybeArray ? maybeArray.filter(function (x) {
      return x;
    }).join(separator || '') : '';
  }

  /**
   * Given array, print each item on its own line, wrapped in an
   * indented "{ }" block.
   */
  function block(array) {
    return array && array.length !== 0 ? indent('{\n' + join(array, '\n')) + '\n}' : '{}';
  }

  /**
   * If maybeString is not null or empty, then wrap with start and end, otherwise
   * print an empty string.
   */
  function wrap(start, maybeString, end) {
    return maybeString ? start + maybeString + (end || '') : '';
  }

  function indent(maybeString) {
    return maybeString && maybeString.replace(/\n/g, '\n  ');
  }
  });

  var printer$1 = unwrapExports(printer);
  var printer_1 = printer.print;

  var language = createCommonjsModule(function (module, exports) {

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.BREAK = exports.getVisitFn = exports.visitWithTypeInfo = exports.visitInParallel = exports.visit = exports.Source = exports.print = exports.parseType = exports.parseValue = exports.parse = exports.TokenKind = exports.createLexer = exports.Kind = exports.getLocation = undefined;



  Object.defineProperty(exports, 'getLocation', {
    enumerable: true,
    get: function get() {
      return location_1.getLocation;
    }
  });



  Object.defineProperty(exports, 'createLexer', {
    enumerable: true,
    get: function get() {
      return lexer.createLexer;
    }
  });
  Object.defineProperty(exports, 'TokenKind', {
    enumerable: true,
    get: function get() {
      return lexer.TokenKind;
    }
  });



  Object.defineProperty(exports, 'parse', {
    enumerable: true,
    get: function get() {
      return parser.parse;
    }
  });
  Object.defineProperty(exports, 'parseValue', {
    enumerable: true,
    get: function get() {
      return parser.parseValue;
    }
  });
  Object.defineProperty(exports, 'parseType', {
    enumerable: true,
    get: function get() {
      return parser.parseType;
    }
  });



  Object.defineProperty(exports, 'print', {
    enumerable: true,
    get: function get() {
      return printer.print;
    }
  });



  Object.defineProperty(exports, 'Source', {
    enumerable: true,
    get: function get() {
      return source.Source;
    }
  });



  Object.defineProperty(exports, 'visit', {
    enumerable: true,
    get: function get() {
      return visitor.visit;
    }
  });
  Object.defineProperty(exports, 'visitInParallel', {
    enumerable: true,
    get: function get() {
      return visitor.visitInParallel;
    }
  });
  Object.defineProperty(exports, 'visitWithTypeInfo', {
    enumerable: true,
    get: function get() {
      return visitor.visitWithTypeInfo;
    }
  });
  Object.defineProperty(exports, 'getVisitFn', {
    enumerable: true,
    get: function get() {
      return visitor.getVisitFn;
    }
  });
  Object.defineProperty(exports, 'BREAK', {
    enumerable: true,
    get: function get() {
      return visitor.BREAK;
    }
  });



  var Kind = _interopRequireWildcard(kinds);

  function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

  exports.Kind = Kind;
  });

  unwrapExports(language);
  var language_1 = language.BREAK;
  var language_2 = language.getVisitFn;
  var language_3 = language.visitWithTypeInfo;
  var language_4 = language.visitInParallel;
  var language_5 = language.visit;
  var language_6 = language.Source;
  var language_7 = language.print;
  var language_8 = language.parseType;
  var language_9 = language.parseValue;
  var language_10 = language.parse;
  var language_11 = language.TokenKind;
  var language_12 = language.createLexer;
  var language_13 = language.Kind;
  var language_14 = language.getLocation;

  // console.log(PusherLink)

  function ActionCableLink(options) {
    var cable = options.cable;
    var channelName = options.channelName || "GraphqlChannel";
    var actionName = options.actionName || "execute";
    var connectionParams = options.connectionParams;

    if (_typeof(connectionParams) !== "object") {
      connectionParams = {};
    }

    return new apolloLink.ApolloLink(function (operation) {
      return new apolloLink.Observable(function (observer) {
        var channelId = Math.round(Date.now() + Math.random() * 100000).toString(16);
        var subscription = cable.subscriptions.create(Object.assign({}, {
          channel: channelName,
          channelId: channelId
        }, connectionParams), {
          connected: function connected() {
            this.perform(actionName, {
              query: operation.query ? language_7(operation.query) : null,
              variables: operation.variables,
              operationId: operation.operationId,
              operationName: operation.operationName
            });
          },
          received: function received(payload) {
            if (payload.result.data) {
              observer.next(payload.result);
            }

            if (!payload.more) {
              this.unsubscribe();
              observer.complete();
            }
          }
        });
        return subscription;
      });
    });
  }

  // State management for subscriptions.
  // Used to add subscriptions to an Apollo network intrface.
  var registry = {
    // Apollo expects unique ids to reference each subscription,
    // here's a simple incrementing ID generator which starts at 1
    // (so it's always truthy)
    _id: 1,
    // Map{id => <#unsubscribe()>}
    // for unsubscribing when Apollo asks us to
    _subscriptions: {},
    add: function add(subscription) {
      var id = this._id++;
      this._subscriptions[id] = subscription;
      return id;
    },
    unsubscribe: function unsubscribe(id) {
      var subscription = this._subscriptions[id];

      if (!subscription) {
        throw new Error("No subscription found for id: " + id);
      }

      subscription.unsubscribe();
      delete this._subscriptions[id];
    }
  };

  /**
   * Make a new subscriber for `addGraphQLSubscriptions`
   * @param {ActionCable.Consumer} cable ActionCable client
  */

  function ActionCableSubscriber(cable, networkInterface) {
    this._cable = cable;
    this._networkInterface = networkInterface;
  }
  /**
   * Send `request` over ActionCable (`registry._cable`),
   * calling `handler` with any incoming data.
   * Return the subscription so that the registry can unsubscribe it later.
   * @param {Object} registry
   * @param {Object} request
   * @param {Function} handler
   * @return {ID} An ID for unsubscribing
  */


  ActionCableSubscriber.prototype.subscribe = function subscribeToActionCable(request, handler) {
    var networkInterface = this._networkInterface; // unique-ish

    var channelId = Math.round(Date.now() + Math.random() * 100000).toString(16);

    var channel = this._cable.subscriptions.create({
      channel: "GraphqlChannel",
      channelId: channelId
    }, {
      // After connecting, send the data over ActionCable
      connected: function connected() {
        var _this = this; // applyMiddlewares code is inspired by networkInterface internals


        var opts = Object.assign({}, networkInterface._opts);
        networkInterface.applyMiddlewares({
          request: request,
          options: opts
        }).then(function () {
          var queryString = request.query ? printer$1.print(request.query) : null;
          var operationName = request.operationName;
          var operationId = request.operationId;
          var variables = JSON.stringify(request.variables);
          var channelParams = Object.assign({}, request, {
            query: queryString,
            variables: variables,
            operationId: operationId,
            operationName: operationName
          }); // This goes to the #execute method of the channel

          _this.perform("execute", channelParams);
        });
      },
      // Payload from ActionCable should have at least two keys:
      // - more: true if this channel should stay open
      // - result: the GraphQL response for this result
      received: function received(payload) {
        if (!payload.more) {
          registry.unsubscribe(this);
        }

        var result = payload.result;

        if (result) {
          handler(result.errors, result.data);
        }
      }
    });

    var id = registry.add(channel);
    return id;
  };
  /**
   * End the subscription.
   * @param {ID} id An ID from `.subscribe`
   * @return {void}
  */


  ActionCableSubscriber.prototype.unsubscribe = function (id) {
    registry.unsubscribe(id);
  };

  var PusherLink =
  /*#__PURE__*/
  function (_ApolloLink) {
    _inherits(PusherLink, _ApolloLink);

    function PusherLink(options) {
      var _this;

      _classCallCheck(this, PusherLink);

      _this = _possibleConstructorReturn(this, _getPrototypeOf(PusherLink).call(this)); // Retain a handle to the Pusher client

      _this.pusher = options.pusher;
      return _this;
    }

    _createClass(PusherLink, [{
      key: "request",
      value: function request(operation, forward) {
        var _this2 = this;

        var subscribeObservable = new apolloLink.Observable(function (observer) {}); // Capture the super method

        var prevSubscribe = subscribeObservable.subscribe.bind(subscribeObservable); // Override subscribe to return an `unsubscribe` object, see
        // https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L182-L212

        subscribeObservable.subscribe = function (observerOrNext, onError, onComplete) {
          // Call super
          prevSubscribe(observerOrNext, onError, onComplete);
          var observer = getObserver(observerOrNext, onError, onComplete);
          var subscriptionChannel = null; // Check the result of the operation

          var resultObservable = forward(operation); // When the operation is done, try to get the subscription ID from the server

          resultObservable.subscribe({
            next: function next(data) {
              // If the operation has the subscription header, it's a subscription
              var response = operation.getContext().response; // Check to see if the response has the header

              subscriptionChannel = response.headers.get("X-Subscription-ID");

              if (subscriptionChannel) {
                // Set up the pusher subscription for updates from the server
                var pusherChannel = _this2.pusher.subscribe(subscriptionChannel); // Subscribe for more update


                pusherChannel.bind("update", function (payload) {
                  if (!payload.more) {
                    // This is the end, the server says to unsubscribe
                    pusher.unsubscribe(subscriptionChannel);
                    observer.complete();
                  }

                  var result = payload.result;

                  if (result) {
                    // Send the new response to listeners
                    observer.next(result);
                  }
                });
              } else {
                // This isn't a subscription,
                // So pass the data along and close the observer.
                observer.next(data);
                observer.complete();
              }
            }
          }); // Return an object that will unsubscribe _if_ the query was a subscription.

          return {
            unsubscribe: function unsubscribe() {
              subscriptionChannel && _this2.pusher.unsubscribe(subscriptionChannel);
            }
          };
        };

        return subscribeObservable;
      }
    }]);

    return PusherLink;
  }(apolloLink.ApolloLink); // Turn `subscribe` arguments into an observer-like thing, see getObserver
  // https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L329-L343


  function getObserver(observerOrNext, onError, onComplete) {
    if (typeof observerOrNext === 'function') {
      // Duck-type an observer
      return {
        next: function next(v) {
          return observerOrNext(v);
        },
        error: function error(e) {
          return onError && onError(e);
        },
        complete: function complete() {
          return onComplete && onComplete();
        }
      };
    } else {
      // Make an object that calls to the given object, with safety checks
      return {
        next: function next(v) {
          return observerOrNext.next && observerOrNext.next(v);
        },
        error: function error(e) {
          return observerOrNext.error && observerOrNext.error(e);
        },
        complete: function complete() {
          return observerOrNext.complete && observerOrNext.complete();
        }
      };
    }
  }

  /**
   * Make a new subscriber for `addGraphQLSubscriptions`
   *
   * @param {Pusher} pusher
  */

  function PusherSubscriber(pusher, networkInterface) {
    this._pusher = pusher;
    this._networkInterface = networkInterface; // This is a bit tricky:
    // only the _request_ is passed to the `subscribe` function, s
    // so we have to attach the subscription id to the `request`.
    // However, the request is _not_ available in the afterware function.
    // So:
    // - Add the request to `options` so it's available in afterware
    // - In the afterware, update the request to hold the header value
    // - Finally, in `subscribe`, read the subscription ID off of `request`

    networkInterface.use([{
      applyMiddleware: function applyMiddleware(_ref, next) {
        var request = _ref.request,
            options = _ref.options;
        options.request = request;
        next();
      }
    }]);
    networkInterface.useAfter([{
      applyAfterware: function applyAfterware(_ref2, next) {
        var response = _ref2.response,
            options = _ref2.options;
        options.request.__subscriptionId = response.headers.get("X-Subscription-ID");
        next();
      }
    }]);
  } // Implement the Apollo subscribe API


  PusherSubscriber.prototype.subscribe = function (request, handler) {
    var pusher = this._pusher;
    var networkInterface = this._networkInterface;
    var subscription = {
      _channelName: null,
      // set after the successful POST
      unsubscribe: function unsubscribe() {
        pusher.unsubscribe(this._channelName);
      } // Send the subscription as a query
      // Get the channel ID from the response headers

    };
    networkInterface.query(request).then(function (executionResult) {
      var subscriptionChannel = request.__subscriptionId;
      subscription._channelName = subscriptionChannel;
      var pusherChannel = pusher.subscribe(subscriptionChannel); // When you get an update form Pusher, send it to Apollo

      pusherChannel.bind("update", function (payload) {
        if (!payload.more) {
          registry.unsubscribe(subscription);
        }

        var result = payload.result;

        if (result) {
          handler(result.errors, result.data);
        }
      });
    });
    var id = registry.add(subscription);
    return id;
  }; // Implement the Apollo unsubscribe API


  PusherSubscriber.prototype.unsubscribe = function (id) {
    registry.unsubscribe(id);
  };

  /**
   * Modify an Apollo network interface to
   * subscribe an unsubscribe using `cable:`.
   * Based on `addGraphQLSubscriptions` from `subscriptions-transport-ws`.
   *
   * This function assigns `.subscribe` and `.unsubscribe` functions
   * to the provided networkInterface.
   * @example Adding ActionCable subscriptions to a HTTP network interface
   *   // Load ActionCable and create a consumer
   *   var ActionCable = require('actioncable')
   *   var cable = ActionCable.createConsumer()
   *   window.cable = cable
   *
   *   // Load ApolloClient and create a network interface
   *   var apollo = require('apollo-client')
   *   var RailsNetworkInterface = apollo.createNetworkInterface({
   *     uri: '/graphql',
   *     opts: {
   *       credentials: 'include',
   *     },
   *     headers: {
   *       'X-CSRF-Token': $("meta[name=csrf-token]").attr("content"),
   *     }
   *   });
   *
   *   // Add subscriptions to the network interface
   *   var addGraphQLSubscriptions = require("graphql-ruby-client/subscriptions/addGraphQLSubscriptions")
   *   addGraphQLSubscriptions(RailsNetworkInterface, {cable: cable})
   *
   *   // Optionally, add persisted query support:
   *   var OperationStoreClient = require("./OperationStoreClient")
   *   RailsNetworkInterface.use([OperationStoreClient.apolloMiddleware])
   *
   * @example Subscriptions with Pusher & graphql-pro
   *   var pusher = new Pusher(appId, options)
   *   addGraphQLSubscriptions(RailsNetworkInterface, {pusher: pusher})
   *
   * @param {Object} networkInterface - an HTTP NetworkInterface
   * @param {ActionCable.Consumer} options.cable - A cable for subscribing with
   * @param {Pusher} options.pusher - A pusher client for subscribing with
   * @return {void}
  */

  function addGraphQLSubscriptions(networkInterface, options) {
    if (!options) {
      options = {};
    }

    var subscriber;

    if (options.subscriber) {
      // Right now this is just for testing
      subscriber = options.subscriber;
    } else if (options.cable) {
      subscriber = new ActionCableSubscriber(options.cable, networkInterface);
    } else if (options.pusher) {
      subscriber = new PusherSubscriber(options.pusher, networkInterface);
    } else {
      throw new Error("Must provide cable: or pusher: option");
    }

    var networkInterfaceWithSubscriptions = Object.assign(networkInterface, {
      subscribe: function subscribe(request, handler) {
        var id = subscriber.subscribe(request, handler);
        return id;
      },
      unsubscribe: function unsubscribe(id) {
        subscriber.unsubscribe(id);
      }
    });
    return networkInterfaceWithSubscriptions;
  }

  // TODO:
  // - end-to-end test
  // - extract update code, inject it as a function?
  function createAblyHandler(options) {
    var ably = options.ably;
    var operations = options.operations;
    var fetchOperation = options.fetchOperation;
    return function (operation, variables, cacheConfig, observer) {
      var channelName, channel; // POST the subscription like a normal query

      fetchOperation(operation, variables, cacheConfig).then(function (response) {
        channelName = response.headers.get("X-Subscription-ID");
        channel = ably.channels.get(channelName); // Register presence, so that we can detect empty channels and clean them up server-side

        if (ably.auth.clientId) {
          channel.presence.enter("subscribed");
        } else {
          channel.presence.enterClient("graphql-subscriber", "subscribed");
        } // When you get an update from ably, give it to Relay


        channel.subscribe("update", function (message) {
          // TODO Extract this code
          // When we get a response, send the update to `observer`
          var payload = message.data;
          var result = payload.result;

          if (result && result.errors) {
            // What kind of error stuff belongs here?
            observer.onError(result.errors);
          } else if (result) {
            observer.onNext({
              data: result.data
            });
          }

          if (!payload.more) {
            // Subscription is finished
            observer.onCompleted();
          }
        });
      });
      return {
        dispose: function dispose() {
          channel.presence.leaveClient();
          channel.unsubscribe();
        }
      };
    };
  }

  /**
   * Create a Relay Modern-compatible subscription handler.
   *
   * @param {ActionCable.Consumer} cable - An ActionCable consumer from `.createConsumer`
   * @param {OperationStoreClient} operations - A generated OperationStoreClient for graphql-pro's OperationStore
   * @return {Function}
  */
  function createActionCableHandler(cable, operations) {
    return function (operation, variables, cacheConfig, observer) {
      // unique-ish
      var channelId = Math.round(Date.now() + Math.random() * 100000).toString(16); // Register the subscription by subscribing to the channel

      var subscription = cable.subscriptions.create({
        channel: "GraphqlChannel",
        channelId: channelId
      }, {
        connected: function connected() {
          // Once connected, send the GraphQL data over the channel
          var channelParams = {
            variables: variables,
            operationName: operation.name // Use the stored operation alias if possible

          };

          if (operations) {
            channelParams.operationId = operations.getOperationId(operation.name);
          } else {
            channelParams.query = operation.text;
          }

          this.perform("execute", channelParams);
        },
        received: function received(payload) {
          // When we get a response, send the update to `observer`
          var result = payload.result;

          if (result && result.errors) {
            // What kind of error stuff belongs here?
            observer.onError(result.errors);
          } else if (result) {
            observer.onNext({
              data: result.data
            });
          }

          if (!payload.more) {
            // Subscription is finished
            observer.onCompleted();
          }
        }
      }); // Return an object for Relay to unsubscribe with

      return {
        dispose: function dispose() {
          subscription.unsubscribe();
        }
      };
    };
  }

  // TODO:
  // - end-to-end test
  // - extract update code, inject it as a function?
  function createPusherHandler(options) {
    var pusher = options.pusher;
    var operations = options.operations;
    var fetchOperation = options.fetchOperation;
    return function (operation, variables, cacheConfig, observer) {
      var channelName; // POST the subscription like a normal query

      fetchOperation(operation, variables, cacheConfig).then(function (response) {
        channelName = response.headers.get("X-Subscription-ID");
        channel = pusher.subscribe(channelName); // When you get an update from pusher, give it to Relay

        channel.bind("update", function (payload) {
          // TODO Extract this code
          // When we get a response, send the update to `observer`
          var result = payload.result;

          if (result && result.errors) {
            // What kind of error stuff belongs here?
            observer.onError(result.errors);
          } else if (result) {
            observer.onNext({
              data: result.data
            });
          }

          if (!payload.more) {
            // Subscription is finished
            observer.onCompleted();
          }
        });
      });
      return {
        dispose: function dispose() {
          pusher.unsubscribe(channelName);
        }
      };
    };
  }

  /**
   * Transport-agnostic wrapper for Relay Modern subscription handlers.
   * @example Add ActionCable subscriptions
   *   var subscriptionHandler = createHandler({
   *     cable: cable,
   *     operations: OperationStoreClient,
   *   })
   *   var network = Network.create(fetchQuery, subscriptionHandler)
   * @param {ActionCable.Consumer} options.cable - A consumer from `.createConsumer`
   * @param {Pusher} options.pusher - A Pusher client
   * @param {Ably.Realtime} options.ably - An Ably client
   * @param {OperationStoreClient} options.operations - A generated `OperationStoreClient` for graphql-pro's OperationStore
   * @return {Function} A handler for a Relay Modern network
  */

  function createHandler(options) {
    if (!options) {
      options = {};
    }

    var handler;

    if (options.cable) {
      handler = createActionCableHandler(options.cable, options.operations);
    } else if (options.pusher) {
      handler = createPusherHandler(options);
    } else if (options.ably) {
      handler = createAblyHandler(options);
    }

    return handler;
  }

  // @create-index

  exports.AblyLink = AblyLink;
  exports.ActionCableLink = ActionCableLink;
  exports.ActionCableSubscriber = ActionCableSubscriber;
  exports.PusherLink = PusherLink;
  exports.PusherSubscriber = PusherSubscriber;
  exports.addGraphQLSubscriptions = addGraphQLSubscriptions;
  exports.createAblyHandler = createAblyHandler;
  exports.createActionCableHandler = createActionCableHandler;
  exports.createHandler = createHandler;
  exports.createPusherHandler = createPusherHandler;
  exports.registry = registry;

  Object.defineProperty(exports, '__esModule', { value: true });

}));
