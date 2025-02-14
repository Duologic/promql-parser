local lexer = import './lexer.libsonnet';

{
  test: import './parser_test.libsonnet',

  new(file):: {
    local this = self,
    local lexicon = lexer.lex(file),

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

    parseExpr(index, endTokens):
      local token = lexicon[index];
      assert std.trace(std.manifestJson(index), true);
      assert std.trace(std.manifestJson(token), true);
      local expr =
        if token[0] == 'IDENTIFIER'
        then self.parseIdentifier(index, endTokens)
        else if std.member(['STRING_SINGLE', 'STRING_DOUBLE', 'STRING_BACKTICK'], token[0])
        then self.parseString(index, endTokens)
        else if token[0] == 'OPERATOR'
        then self.parseUnary(index, endTokens)
        else if std.member(['NUMBER', 'HEX'], token[0])
        then self.parseNumber(index, endTokens)
        else if token[0] == 'DURATION'
        then self.parseDuration(index, endTokens)
        else if token[1] == '{'
        then self.parseSelector(index, endTokens)
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
            else if token[1] == '('
            then self.parseFunctioncall(obj, endTokens)
            else if std.member(['by', 'without'], token[1])
            then self.parseAggregationExpr(obj, endTokens)
            else if token[1] == '{'
            then self.parseVectorSelector(obj, endTokens)
            else if token[1] == '['
            then self.parseRange(obj, endTokens)
            else if token[1] == 'offset'
            then self.parseOffsetModifier(obj, endTokens)
            else if token[1] == '@'
            then self.parseTimestampModifier(obj, endTokens)
            else
              error 'Unexpected token: "%s"' % std.toString(token) + std.toString(endTokens);
          parseRemainder(expr + { location:: lexicon[obj.cursor][2] });

      parseRemainder(expr + { location:: lexicon[index][2] }),

    parseIdentifier(index, endTokens):
      local token = lexicon[index];
      local tokenValue = token[1];
      {
        type: 'vector_selector',
        name: tokenValue,
        vector_selector:: tokenValue,  // used to get the value in parseStringOrId()
        cursor:: index + 1,
      },

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
      assert std.member(['number', 'duration'], expr.type) : "Unexpected type '%s' after unary operator" % expr.type;
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

    parseDuration(index, endTokens):
      local token = lexicon[index];
      local tokenValue = token[1];
      {
        type: 'duration',
        duration: tokenValue,
        cursor:: index + 1,
      },

    parseSelector(index, endTokens):
      local endToken = '}';
      local endTokens = [endToken];

      local token = lexicon[index];
      assert token[1] == '{' : expmsg('{', token);

      local matchers =
        parseTokens(
          index + 1,
          endTokens,
          parseLabelMatcher,
        );

      local lastMatcher = std.reverse(matchers)[0];
      local cursor =
        if std.length(matchers) > 0
        then lastMatcher.cursor
        else index + 1;

      assert lexicon[cursor][1] == endToken : expmsg(endToken, lexicon[cursor]);
      {
        type: 'vector_selector',
        matchers: matchers,
        cursor:: cursor + 1,
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

      local operator = lexicon[index][1];
      assert std.member(validoperators, operator) : 'Not a binary operator: ' + lexicon[index];

      local isBool =
        if lexicon[index + 1][1] == 'bool'
        then true
        else false;

      assert !isBool || std.member(compoperators, operator) : 'bool modifier can only be used on comparison operators';

      local nextIndex =
        if isBool
        then index + 2
        else index + 1;

      local vectorMatching =
        if lexicon[nextIndex][0] == 'KEYWORD'
        then parseVectorMatching(index + 1, endTokens)
        else null;

      local vectorMatcherCursor =
        if vectorMatching != null
        then vectorMatching.cursor
        else nextIndex;

      local rightExpr = self.parseExpr(vectorMatcherCursor, endTokens);
      {
        type: 'binary',
        operator: operator,
        [if isBool then 'bool']: isBool,
        [if vectorMatching != null then 'vector_matching']: vectorMatching,
        lhs: leftExpr,
        rhs: rightExpr,
        cursor:: rightExpr.cursor,
      },

    parseFunctioncall(obj, endTokens):
      if std.member(aggregationOperators, obj.name)
      then self.parseAggregationExpr(obj, endTokens)
      else
        local functioncall = obj.name;
        local endToken = ')';
        local endTokens = [endToken];
        local args = parseFunctionargs(obj.cursor, endTokens);
        {
          type: 'functioncall',
          func: functioncall,
          args: args.args,
          cursor:: args.cursor,
        },

    parseAggregationExpr(obj, endTokens):
      local operator = obj.name;
      assert std.member(aggregationOperators, operator) : expmsg(aggregationOperators, operator);

      local parseClause(index, endTokens) =
        local token = lexicon[index];
        local keywords = ['by', 'without'];
        local keyword = token[1];
        assert std.member(keywords, keyword) : expmsg(keywords, keyword);
        local labelList = parseLabelList(index + 1, endTokens);
        {
          keyword: keyword,
          grouping: labelList.label_list,
          cursor:: labelList.cursor,
        };

      local clauseBefore =
        if lexicon[obj.cursor][0] == 'KEYWORD'
        then parseClause(obj.cursor, endTokens)
        else {};

      local clauseLeftCursor =
        if clauseBefore != {}
        then clauseBefore.cursor
        else obj.cursor;

      local parameters = parseFunctionargs(clauseLeftCursor, endTokens);

      local clauseAfter =
        if std.length(lexicon) > parameters.cursor && lexicon[parameters.cursor][0] == 'KEYWORD'
        then parseClause(parameters.cursor, endTokens)
        else {};

      local cursor =
        if clauseAfter != {}
        then clauseAfter.cursor
        else parameters.cursor;

      local clause = clauseBefore + clauseAfter;

      local hasParam = [
        'count_values',
        'quantile',
        'topk',
        'bottomk',
        'limitk',
        'limit_ratio',
      ];

      assert std.member(hasParam, operator) || std.length(parameters.args) == 1 : 'wrong number of arguments for aggregate expression provided, expected 1, got 2';
      assert !std.member(hasParam, operator) || std.length(parameters.args) == 2 : 'wrong number of arguments for aggregate expression provided, expected 2, got 1';

      local param = parameters.args[0:-1];
      local expr = parameters.args[std.length(parameters.args) - 1];
      {
        type: 'aggregate',
        operator: operator,
        expr: expr,
        [if std.get(clause, 'keyword', '') == 'without' then 'without']: true,
        [if clause != {} then 'grouping']: clause.grouping,
        [if std.length(param) > 0 then 'param']: param[0],
        cursor:: cursor,
      },

    parseVectorSelector(obj, endTokens):
      self.parseSelector(obj.cursor, endTokens)
      + { name: obj.name },

    parseRange(obj, endTokens):
      local endToken = ']';
      local expr = self.parseExpr(obj.cursor + 1, [endToken]);
      local expectedTypes = ['number', 'duration'];
      assert std.member(expectedTypes, expr.type) : expmsg(expectedTypes, expr.type);
      assert lexicon[expr.cursor][1] == endToken : expmsg(endToken, lexicon[expr.cursor]);
      obj
      + {
        range: expr,
        cursor:: expr.cursor + 1,
      },

    parseOffsetModifier(obj, endTokens):
      local token = lexicon[obj.cursor];
      local tokenValue = token[1];
      assert tokenValue == 'offset' : expmsg('offset', tokenValue);

      local value = self.parseExpr(obj.cursor + 1, endTokens + ['@']);
      local expectedTypes = ['number', 'duration'];
      assert std.member(expectedTypes, value.type) : expmsg(expectedTypes, value.type);

      assert obj.type == 'vector_selector' : expmsg('vector_selector', obj);
      assert !std.objectHas(obj, 'offset') : 'offset may not be set multiple times';

      obj
      + {
        offset: value,
        cursor:: value.cursor,
      },

    parseTimestampModifier(obj, endTokens):
      local token = lexicon[obj.cursor];
      local tokenValue = token[1];
      assert tokenValue == '@' : expmsg('@', tokenValue);

      local value = self.parseExpr(obj.cursor + 1, endTokens + ['offset']);
      local expectedTypes = ['number', 'duration', 'functioncall'];
      assert std.member(expectedTypes, value.type) : expmsg(expectedTypes, value.type);
      assert
        (if value.type == 'functioncall'
         then std.member(['start', 'end'], value.func) && value.args == []
         else true) : expmsg(['start', 'end'], value.func);

      assert obj.type == 'vector_selector' : expmsg('vector_selector', obj);

      assert !std.objectHas(obj, 'timestamp') : '@ <timestamp> may not be set multiple times';

      obj
      + {
        [if value.type != 'functioncall' then 'timestamp']+: value,
        [if value.type == 'functioncall' then 'start_end']: value.func,
        cursor:: value.cursor,
      },

    local parseLabelMatcher(index, endTokens) =
      local expectedOperators = ['=', '!=', '=~', '!~'];
      local key = parseStringOrId(index, expectedOperators);
      local operator = lexicon[key.cursor][1];
      assert std.member(expectedOperators, operator) : expmsg(std.join('","', expectedOperators), lexicon[key.cursor]);
      local expr = self.parseString(key.cursor + 1, endTokens);
      {
        type: 'label_matcher',
        key: key.value,
        value: expr.string,
        operator: operator,
        cursor:: expr.cursor,
      },

    local parseVectorMatching(index, endTokens) =
      local keywords = ['on', 'ignoring'];

      local keyword = lexicon[index][1];
      assert std.member(keywords, keyword) : expmsg(keywords, keyword);

      local matchingLabels = parseLabelList(index + 1, endTokens);

      local groupKeywords = ['group_left', 'group_right'];
      local groupModifier =
        if std.member(groupKeywords, lexicon[matchingLabels.cursor][1])
        then parseGroupModifier(matchingLabels.cursor, endTokens)
        else null;

      local cursor =
        if groupModifier != null
        then groupModifier.cursor
        else matchingLabels.cursor;
      {
        type: 'vector_matching',
        vector_matching: keyword,
        matching_labels: matchingLabels.label_list,
        [if groupModifier != null then 'group_modifier']: groupModifier,
        cursor:: cursor,
      },

    local parseFunctionargs(index, endTokens) =
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

    local parseGroupModifier(index, endTokens) =
      local keywords = ['group_left', 'group_right'];

      local keyword = lexicon[index][1];
      assert std.member(keywords, keyword);

      local labelList =
        if lexicon[index + 1][1] == '('
        then parseLabelList(index + 1, endTokens)
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

    local parseLabelList(index, endTokens) =
      local endToken = ')';
      local endTokens = [endToken];

      local token = lexicon[index];
      assert token[1] == '(' : expmsg('(', token);

      local list = parseTokens(
        index + 1,
        endTokens,
        parseStringOrId,
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

    local parseStringOrId(index, endTokens) =
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
  },
}
