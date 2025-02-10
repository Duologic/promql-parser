local lexer = import './lexer.libsonnet';

{
  test: import './parser_test.libsonnet',

  new(file):: {
    local this = self,
    local lexicon = lexer.lex(file),

    local expmsg(expected, actual) =
      'Expected "%s" but got "%s"' % [std.toString(expected), std.toString(actual)],

    local parseTokens(index, endTokens, parseF, splitTokens=[',']) =
      local infunc(index) =
        local token = lexicon[index];
        if std.member(endTokens, token[1])
        then []
        else (
          local item = parseF(index, endTokens + splitTokens);
          assert std.length(lexicon) > item.cursor
                 : 'Expected %s before next item but got end of file'
                   % [std.toString(splitTokens + endTokens)];
          local nextToken = lexicon[item.cursor];
          if std.member(endTokens, nextToken[1])
          then [item]
          else if std.member(splitTokens, nextToken[1])
          then [item + { cursor+:: 1 }]
               + infunc(item.cursor + 1)
          else error 'Expected %s before next item but got "%s"' % [std.toString(splitTokens), token]
        );
      infunc(index),

    parse():
      self.parseExpr(index=0, endTokens=[]),

    local aggregationOperators = [
      'sum',
      'min',
      'max',
      'avg',
      'group',
      'stddev',
      'stdvar',
      'count',
      'count_values',
      'bottomk',
      'topk',
      'quantile',
      'limitk',
      'limit_ratio',
    ],

    parseExpr(index, endTokens):
      local token = lexicon[index];
      assert std.trace(std.manifestJson(index), true);
      assert std.trace(std.manifestJson(token), true);
      local expr =
        if std.member(aggregationOperators, token[1])
        then self.parseAggregationOperator(index, endTokens)
        else if token[0] == 'IDENTIFIER' && std.length(lexicon) > index + 1 && lexicon[index + 1][1] == '('
        then self.parseFunctioncall(index, endTokens)
        else if token[0] == 'IDENTIFIER'
        then self.parseVectorSelector(index, endTokens)
        else if token[1] == '{'
        then self.parseSelector(index, endTokens)
        else if std.member(['STRING_SINGLE', 'STRING_DOUBLE', 'STRING_BACKTICK'], token[0])
        then self.parseString(index, endTokens)
        else if token[0] == 'OPERATOR'
        then self.parseUnary(index, endTokens)
        else if std.member(['NUMBER', 'HEX'], token[0])
        then self.parseNumber(index, endTokens)
        else if token[0] == 'TIME'
        then self.parseTime(index, endTokens)
        else error 'Unexpected token: "%s"' % std.toString(token);

      local parseRemainder(obj) =
        if obj.cursor == std.length(lexicon)
           || std.member(endTokens, lexicon[obj.cursor][1])
        then obj
        else
          local token = lexicon[obj.cursor];
          local expr =
            if token[0] == 'OPERATOR'
            then self.parseBinary(obj, endTokens)
            else
              error 'Unexpected token: "%s"' % std.toString(token) + std.toString(endTokens);
          parseRemainder(expr + { location:: lexicon[obj.cursor][2] });

      parseRemainder(expr + { location:: lexicon[index][2] }),

    parseString(index, endTokens):
      local token = lexicon[index];
      local tokenValue = token[1];
      local expected = ['STRING_SINGLE', 'STRING_DOUBLE', 'STRING_BACKTICK'];
      assert std.member(expected, token[0]) : expmsg(expected, token);
      {
        type: 'string',
        string: tokenValue[1:std.length(tokenValue) - 1],
        cursor:: index + 1,
      },

    parseUnary(index, endTokens):
      local unaryoperators = [
        '-',
        '+',
      ];
      local token = lexicon[index];
      assert std.member(unaryoperators, token[1]) : 'Not a unary operator: ' + std.toString(token);
      local expr = self.parseExpr(index + 1, endTokens);
      assert std.member(['number', 'time'], expr.type) : "Unexpected type '%s' after unary operator" % expr.type;
      {
        type: expr.type,
        [expr.type]: token[1] + expr[expr.type],
        cursor:: expr.cursor,
      },

    parseNumber(index, endTokens):
      local token = lexicon[index];
      local tokenValue = token[1];
      {
        type: 'number',
        number: tokenValue,
        cursor:: index + 1,
      },

    parseTime(index, endTokens):
      local token = lexicon[index];
      local tokenValue = token[1];
      {
        type: 'time',
        time: tokenValue,
        cursor:: index + 1,
      },

    parseIdentifier(index, endTokens):
      local token = lexicon[index];
      local tokenValue = token[1];
      {
        type: 'metric',
        metric: tokenValue,
        cursor:: index + 1,
      },

    parseVectorSelector(index, endTokens):
      local token = lexicon[index];
      local tokenValue = token[1];
      local selector =
        if std.length(lexicon) > index + 1
           && (std.member(['[', '{'], lexicon[index + 1][1]) || lexicon[index + 1][0] == 'KEYWORD')
        then self.parseSelector(index + 1, endTokens)
        else {};
      local cursor =
        if selector != {}
        then selector.cursor
        else index + 1;
      selector
      + {
        type: 'vector_selector',
        name: tokenValue,
        cursor:: cursor,
      },

    parseSelector(index, endTokens):
      local matchers =
        if lexicon[index][1] == '{'
        then self.parseMatchers(index, endTokens)
        else null;

      local matcherCursor =
        if matchers != null
        then matchers.cursor
        else index;

      local rangeEndToken = ']';
      local range =
        if std.length(lexicon) > matcherCursor && lexicon[matcherCursor][1] == '['
        then
          local expr = self.parseExpr(matcherCursor + 1, [rangeEndToken]);
          local expectedTypes = ['number', 'time'];
          assert std.member(expectedTypes, expr.type) : expmsg(expectedTypes, expr.type);
          assert lexicon[expr.cursor][1] == rangeEndToken : expmsg(rangeEndToken, lexicon[expr.cursor]);
          expr
        else null;

      local rangeCursor =
        if range != null
        then range.cursor + 1
        else matcherCursor;

      local mods =
        std.foldl(
          function(acc, i)
            acc
            + (if std.length(lexicon) > rangeCursor + i && lexicon[rangeCursor + i][0] == 'KEYWORD'
               then
                 [self.parseModifier(rangeCursor + i, endTokens)]
               else []),
          [0, 2],
          []
        );

      local lastMod = std.reverse(mods)[0];
      local cursor =
        if std.length(mods) > 0
        then lastMod.cursor
        else rangeCursor;

      {
        type: 'vector_selector',
        [if matchers != null && matchers.matchers != [] then 'matchers']: matchers,
        [if range != null then 'range']: range[range.type],
        [if mods != [] then 'modifiers']: mods,
        cursor:: cursor,
      },

    parseMatchers(index, endTokens):
      local endToken = '}';
      local endTokens = [endToken];

      local token = lexicon[index];
      assert token[1] == '{' : expmsg('{', token);

      local matchers =
        parseTokens(
          index + 1,
          endTokens,
          self.parseLabelMatcher,
        );

      local lastMatcher = std.reverse(matchers)[0];
      local cursor =
        if std.length(matchers) > 0
        then lastMatcher.cursor
        else index + 1;

      assert lexicon[cursor][1] == endToken : expmsg(endToken, lexicon[cursor]);
      {
        type: 'matchers',
        matchers: matchers,
        cursor:: cursor + 1,
      },

    parseLabelMatcher(index, endTokens):
      local expectedOperators = ['=', '!=', '=~', '!~'];
      local key = self.parseStringOrId(index, expectedOperators);
      local operator = lexicon[key.cursor][1];
      assert std.member(expectedOperators, operator) : expmsg(std.join('","', expectedOperators), lexicon[key.cursor]);
      local expr = self.parseString(key.cursor + 1, endTokens);
      {
        type:: 'label_matcher',
        key: key.value,
        value: expr.string,
        operator: operator,
        cursor:: expr.cursor,
      },

    parseStringOrId(index, endTokens):
      local token = lexicon[index];
      local expr =
        if token[0] == 'IDENTIFIER'
        then self.parseIdentifier(index, endTokens)
        else self.parseString(index, endTokens);
      assert std.trace(std.manifestJson(expr), true);
      assert std.trace(std.manifestJson(endTokens), true);
      {
        value: expr[expr.type],
        cursor:: expr.cursor,
      },

    parseModifier(index, endTokens):
      local token = lexicon[index];
      local expectedModifiers = ['offset', '@'];
      assert std.member(expectedModifiers, token[1]) : expmsg(expectedModifiers, token[1]);

      local value = self.parseExpr(index + 1, endTokens + expectedModifiers);
      local expectedTypes = ['number', 'time', 'functioncall'];
      assert std.member(expectedTypes, value.type) : expmsg(expectedTypes, value.type);
      assert std.trace(std.manifestJson(value), true);
      assert
        (if value.type == 'functioncall'
         then std.member(['start', 'end'], value.functioncall) && value.args == []
         else true) : expmsg(['start', 'end'], value.functioncall);
      {
        type: 'modifier',
        modifier: token[1],
        value: value,
        cursor:: value.cursor,
      },

    parseFunctionargs(index, endTokens):
      local endToken = ')';
      local endTokens = [endToken];

      local token = lexicon[index];
      assert token[1] == '(' : expmsg('(', token);

      local args =
        parseTokens(
          index + 1,
          endTokens,
          self.parseExpr,
        );

      local last = std.reverse(args)[0];
      local cursor =
        if std.length(args) > 0
        then last.cursor
        else index + 1;

      assert lexicon[cursor][1] == endToken : expmsg(endToken, lexicon[cursor]);
      {
        type: 'functionargs',
        args: args,
        cursor:: cursor + 1,
      },

    parseFunctioncall(index, endTokens):
      local token = lexicon[index];
      local functioncall = token[1];
      local endToken = ')';
      local endTokens = [endToken];
      local args = self.parseFunctionargs(index + 1, endTokens);
      {
        type: 'functioncall',
        functioncall: functioncall,
        args: args.args,
        cursor:: args.cursor,
      },

    parseBinary(expr, endTokens):
      local compoperators = [
        '==',
        '!=',
        '>',
        '<',
        '>=',
        '<=',
      ];
      local binaryoperators = [
        '+',
        '-',
        '*',
        '/',
        '%',
        '^',
        'atan2',
        'and',
        'or',
        'unless',
      ];
      local validoperators = compoperators + binaryoperators;
      local index = expr.cursor;
      local leftExpr = expr;

      local binaryop = lexicon[index][1];
      assert std.member(validoperators, binaryop) : 'Not a binary operator: ' + lexicon[index];

      local boolop =
        if lexicon[index + 1][1] == 'bool'
        then true
        else false;

      assert !boolop || std.member(compoperators, binaryop) : 'bool modifier can only be used on comparison operators';

      local nextIndex =
        if boolop
        then index + 2
        else index + 1;

      local vectorMatcher =
        if lexicon[nextIndex][0] == 'KEYWORD'
        then self.parseVectorMatcher(index + 1, endTokens)
        else null;

      local vectorMatcherCursor =
        if vectorMatcher != null
        then vectorMatcher.cursor
        else nextIndex;

      local rightExpr = self.parseExpr(vectorMatcherCursor, endTokens);
      {
        type: 'binary',
        binaryop: binaryop,
        [if boolop then 'bool']: boolop,
        [if vectorMatcher != null then 'vector_matcher']: vectorMatcher,
        left_vector: leftExpr,
        right_vector: rightExpr,
        cursor:: rightExpr.cursor,
      },

    parseLabelList(index, endTokens):
      local endToken = ')';
      local endTokens = [endToken];

      local token = lexicon[index];
      assert token[1] == '(' : expmsg('(', token);

      local list = parseTokens(
        index + 1,
        endTokens,
        self.parseStringOrId,
      );

      local last = std.reverse(list)[0];
      local cursor =
        if std.length(list) > 0
        then last.cursor
        else index + 1;

      assert lexicon[cursor][1] == endToken : expmsg(endToken, lexicon[cursor]);

      {
        type: 'label_list',
        label_list: std.map(function(item) item.value, list),
        cursor:: cursor + 1,
      },

    parseVectorMatcher(index, endTokens):
      local keywords = ['on', 'ignoring'];

      local keyword = lexicon[index][1];
      assert std.member(keywords, keyword) : expmsg(keywords, keyword);

      local labelList = self.parseLabelList(index + 1, endTokens);

      local groupKeywords = ['group_left', 'group_right'];
      local groupModifier =
        if std.member(groupKeywords, lexicon[labelList.cursor][1])
        then self.parseGroupModifier(labelList.cursor, endTokens)
        else null;

      local cursor =
        if groupModifier != null
        then groupModifier.cursor
        else labelList.cursor;
      {
        type: 'vector_matcher',
        vector_matcher: keyword,
        label_list: labelList,
        [if groupModifier != null then 'group_modifier']: groupModifier,
        cursor:: cursor,
      },

    parseGroupModifier(index, endTokens):
      local keywords = ['group_left', 'group_right'];

      local keyword = lexicon[index][1];
      assert std.member(keywords, keyword);

      local labelList =
        if lexicon[index + 1][1] == '('
        then self.parseLabelList(index + 1, endTokens)
        else null;

      local cursor =
        if labelList != null
        then labelList.cursor
        else index + 1;

      {
        type: 'group_modifier',
        group_modifier: keyword,
        [if labelList != null then 'label_list']: labelList,
        cursor:: cursor,
      },

    parseAggregationOperator(index, endTokens):
      local operator = lexicon[index][1];
      assert std.member(aggregationOperators, operator) : expmsg(aggregationOperators, operator);

      local clauseLeft =
        if lexicon[index + 1][0] == 'KEYWORD'
        then self.parseAggregationClause(index + 1, endTokens)
        else {};

      local clauseLeftCursor =
        if clauseLeft != {}
        then clauseLeft.cursor
        else index + 1;

      local parameters = self.parseFunctionargs(clauseLeftCursor, endTokens);

      local clauseRight =
        if std.length(lexicon) > parameters.cursor && lexicon[parameters.cursor][0] == 'KEYWORD'
        then self.parseAggregationClause(parameters.cursor, endTokens)
        else {};

      local cursor =
        if clauseRight != {}
        then clauseRight.cursor
        else parameters.cursor;

      local clause = clauseLeft + clauseRight;

      {
        type: 'aggragation_operator',
        aggragation_operator: operator,
        clause: clause,
        parameters: parameters.args,
        cursor: cursor,
      },

    parseAggregationClause(index, endTokens):
      local token = lexicon[index];
      local keywords = ['by', 'without'];
      local keyword = token[1];
      assert std.member(keywords, keyword) : expmsg(keywords, keyword);

      local labelList = self.parseLabelList(index + 1, endTokens);

      {
        type: 'aggregation_clause',
        aggregation_clause: keyword,
        label_list: labelList,
        cursor:: labelList.cursor,
      },
  },

}
