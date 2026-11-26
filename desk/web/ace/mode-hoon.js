/* Quiz Hoon mode: syntax highlighting and :: line comments, no worker. */
ace.define('ace/mode/hoon_highlight_rules',
  ['require', 'exports', 'module', 'ace/lib/oop', 'ace/mode/text_highlight_rules'],
  function(require, exports) {
    'use strict';
    const oop = require('ace/lib/oop');
    const TextHighlightRules =
      require('ace/mode/text_highlight_rules').TextHighlightRules;
    const HoonHighlightRules = function() {
      this.$rules = {
        start: [
          {token: 'comment', regex: '::.*$'},
          {token: 'string', regex: "'''", next: 'block-string'},
          {token: 'string', regex: "'", next: 'cord'},
          {token: 'string', regex: '"', next: 'tape'},
          {token: 'keyword.operator',
            regex: '[|&=?!%+*^~;:./#$-][|&=?!%+*^~;:./<>_$-]'},
          {token: 'constant.language', regex: '%(?:[a-z][a-z0-9-]*|[.&|])'},
          {token: 'storage.type', regex: '@[a-zA-Z]*'},
          {token: 'constant.numeric', regex: '\\b[0-9][a-zA-Z0-9.]*'},
          {token: 'constant.language', regex: '~[a-z0-9][a-z0-9.-]*'},
          {token: 'paren.lparen', regex: '[\\[({]'},
          {token: 'paren.rparen', regex: '[\\])}]'},
          {token: 'identifier', regex: '[a-z][a-z0-9-]*'}
        ],
        cord: [
          {token: 'constant.language.escape', regex: '\\\\.'},
          {token: 'string', regex: "'", next: 'start'},
          {defaultToken: 'string'}
        ],
        tape: [
          {token: 'constant.language.escape', regex: '\\\\.'},
          {token: 'string', regex: '"', next: 'start'},
          {defaultToken: 'string'}
        ],
        'block-string': [
          {token: 'string', regex: "'''", next: 'start'},
          {defaultToken: 'string'}
        ]
      };
      this.normalizeRules();
    };
    oop.inherits(HoonHighlightRules, TextHighlightRules);
    exports.HoonHighlightRules = HoonHighlightRules;
  });
ace.define('ace/mode/hoon',
  ['require', 'exports', 'module', 'ace/lib/oop', 'ace/mode/text',
    'ace/mode/hoon_highlight_rules'],
  function(require, exports) {
    'use strict';
    const oop = require('ace/lib/oop');
    const TextMode = require('ace/mode/text').Mode;
    const HoonHighlightRules =
      require('ace/mode/hoon_highlight_rules').HoonHighlightRules;
    const Mode = function() {
      this.HighlightRules = HoonHighlightRules;
      this.$behaviour = this.$defaultBehaviour;
    };
    oop.inherits(Mode, TextMode);
    Mode.prototype.lineCommentStart = '::';
    Mode.prototype.$id = 'ace/mode/hoon';
    exports.Mode = Mode;
  });
