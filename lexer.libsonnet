local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

local isValidIdChar(c) =
  (xtd.ascii.isLower(c)
   || xtd.ascii.isUpper(c)
   || xtd.ascii.isNumber(c)
   || c == ':'
   || c == '_');

local stripWhitespace(str) =
  std.stripChars(str, [' ', '\t', '\n', '\r']);

local stripLeadingComments(s) =
  local str = stripWhitespace(s);
  local findIndex(t, s) =
    local f = std.findSubstr(t, s);
    if std.length(f) > 0
    then f[0]
    else std.length(s);
  local stripped =
    if std.startsWith(str, '#')
    then str[findIndex('\n', str):]
    else null;
  if stripped != null
  then stripLeadingComments(stripped)
  else str;

{
  keyword: [
    // matching keywords
    'on',
    'ignoring',

    // group modifiers
    'group_left',
    'group_right',

    // modifiers
    '@',
    'offset',
  ],
  operator: [
    'bool',
    'atan2',
    'and',
    'or',
    'unless',
  ],
  infnan: [
    'nan',
    'inf',
  ],
  time: [
    'ms',
    's',
    'm',
    'h',
    'd',
    'w',
    'y',
  ],

  lexIdentifier(str):
    if xtd.ascii.isNumber(str[0])
    then []
    else
      local aux(index=0, return='') =
        if index < std.length(str) && isValidIdChar(str[index])
        then aux(index + 1, return + str[index])
        else return;
      local value = aux();
      if std.member(self.operator, std.asciiLower(value))
      then ['OPERATOR', value]
      else if std.member(self.infnan, std.asciiLower(value))
      then ['INFNAN', value]
      else if std.member(self.keyword, std.asciiLower(value))
      then ['KEYWORD', value]
      else if value != ''
      then ['IDENTIFIER', value]
      else [],

  lexNumber(str):
    if !xtd.ascii.isNumber(str[0]) && str[0] != '.'
    then []
    else
      local leadingZeros =
        local f(index=0, return='') =
          if index < std.length(str) && str[index] == '0'
          then f(index + 1, return + str[index])
          else return;
        f();

      local removeUnderscore(str) =
        std.strReplace(str, '_', '');

      local decimal(index=0, return='') =
        if index < std.length(str)
        then
          if str[index] == '_'
          then decimal(index + 1, return + str[index])

          else if xtd.ascii.isStringJSONNumeric(removeUnderscore(return + str[index]))
          then decimal(index + 1, return + str[index])

          else if str[index] == '.'
          then
            if index + 1 < std.length(str)
               && xtd.ascii.isNumber(str[index + 1])
            then decimal(index + 1, return + str[index])
            else error "Couldn't lex number, junk after decimal point: '%s'" % str[index + 1]

          else if str[index] == 'e' || str[index] == 'e'
          then
            if index + 1 < std.length(str)
               && xtd.ascii.isNumber(str[index + 1])
               || str[index + 1] == '-'
               || str[index + 1] == '+'
            then decimal(index + 1, return + str[index])
            else error "Couldn't lex number, junk after 'E': '%s'" % str[index + 1]

          // if return was not an exponent, then signs will become operators
          else if std.length(return) > 0 && (str[index] == '-' || str[index] == '+')
                  && (return[std.length(return) - 1] == 'e' || return[std.length(return) - 1] == 'e')
          then
            if index + 1 < std.length(str)
               && xtd.ascii.isNumber(str[index + 1])
            then decimal(index + 1, return + str[index])
            else error "Couldn't lex number, junk after exponent sign: '%s'" % str[index + 1]
          else return
        else return;

      local hexadecimal(index=0, return='') =
        local isHex(c) =
          (std.codepoint(c) >= 97 && std.codepoint(c) < 103)
          || (std.codepoint(c) >= 65 && std.codepoint(c) < 71);
        if index < std.length(str)
        then
          if str[index] == '_'
          then hexadecimal(index + 1, return + str[index])
          else if xtd.ascii.isNumber(str[index])
          then hexadecimal(index + 1, return + str[index])
          else if isHex(str[index])
          then hexadecimal(index + 1, return + str[index])
          else
            return
        else
          return;

      local validCharAfterZero = ['.', 'e', 'E'];
      local value =
        if std.length(leadingZeros) > 0
           && std.length(str) > std.length(leadingZeros)
           && std.member(validCharAfterZero, str[std.length(leadingZeros)])
        then leadingZeros[1:] + decimal(std.length(leadingZeros) - 1)

        else if std.length(leadingZeros) == 1
                && std.member(['x', 'X'], str[std.length(leadingZeros)])
        then leadingZeros + str[std.length(leadingZeros)] + hexadecimal(std.length(leadingZeros) + 1)

        else if str[0] == '.'
        then str[0] + decimal(1)

        else leadingZeros + decimal(std.length(leadingZeros));

      local time =
        local unit =
          std.filter(
            function(x)
              std.startsWith(str[std.length(value):], x),
            self.time
          );
        if std.length(std.findSubstr('.', value)) == 0  // Time units cannot be combined with a floating point.
           && std.length(unit) > 0
        then
          local lex = self.lexNumber(str[std.length(value) + std.length(unit[0]):]);
          value
          + unit[0]
          + (
            if str[std.length(value):] == unit[0]
            then ''
            else if lex != []
            then lex[1]
            else ''
          )

        else value;

      if std.startsWith(value, '0x')
      then ['HEX', value]
      else if time != value
      then ['TIME', time]
      else if value != ''
      then ['NUMBER', value]
      else [],

  lexString(str):
    if std.startsWith(str, "'")
       || std.startsWith(str, '"')
       || std.startsWith(str, '`')
    then self.lexQuotedString(str)
    else [],

  lexQuotedString(str):
    assert std.member(['"', "'", '`'], str[0]) : 'Expected \' or " but got %s' % str[0];

    local startChar = str[0];

    local findLastChar = std.map(function(i) i + 1, std.findSubstr(startChar, str[1:]));

    local isEscaped(index) =
      index > 1
      && str[index - 1] == '\\'
      && !isEscaped(index - 1);

    local lastCharIndices = std.filter(function(e) !isEscaped(e), findLastChar);

    assert std.length(lastCharIndices) > 0 : 'Unterminated String';

    local value = str[1:lastCharIndices[0]];
    local lastChar = str[lastCharIndices[0]];

    local tokenName = {
      '"': 'STRING_DOUBLE',
      "'": 'STRING_SINGLE',
      '`': 'STRING_BACKTICK',
    };

    [tokenName[startChar], startChar + value + lastChar],

  lexSymbol(str):
    local symbols = ['{', '}', '[', ']', ',', '(', ')'];
    if std.member(symbols, str[0])
    then ['SYMBOL', str[0]]
    else [],

  lexOperator(str):
    local ops = ['+', '-', '=', '!', '~', '@', '*', '/', '%', '^', '<', '>'];
    local infunc(s) =
      if s != '' && std.member(ops, s[0])
      then [s[0]]
      else [];
    local q = std.join('', infunc(str));

    if q == '@'
    then ['KEYWORD', q]
    else if q != ''
    then ['OPERATOR', q]
    else [],

  lex(s, prevEndLineNr=0, prevColumnNr=1, prev=[]):
    local str = stripLeadingComments(s);
    if str == ''
    then []
    else
      local lexicons = std.filter(
        function(l) l != [], [
          self.lexString(str),
          self.lexIdentifier(str),
          self.lexNumber(str),
          self.lexSymbol(str),
          self.lexOperator(str),
        ]
      );
      local value = lexicons[0][1];
      assert std.length(lexicons) == 1 : 'Cannot lex: "%s"' % std.manifestJson(prev);
      assert value != '' : 'Cannot lex: "%s"' % str;

      local countNewlines(s) = std.length(std.findSubstr('\n', s));
      local removedNewlinesCount = countNewlines(s) - countNewlines(str);
      local newlinesInLexicon = countNewlines(value);

      local endLineNr =
        prevEndLineNr
        + removedNewlinesCount
        + countNewlines(str[:std.length(value)]);
      local lineNr = endLineNr - newlinesInLexicon;

      local startColumnNr =
        if lineNr > prevEndLineNr
        then 1
        else prevColumnNr;
      local leadingSpacesCount = std.length(std.lstripChars(s, '\n')) - std.length(std.lstripChars(s, ' \n'));

      local columnNr = startColumnNr + leadingSpacesCount;
      local endColumnNr =
        if newlinesInLexicon == 0
        then columnNr + std.length(value)
        else columnNr;

      [lexicons[0] + [{ line: lineNr, column: columnNr }]]
      + (
        local remainder = str[std.length(lexicons[0][1]):];
        if std.length(lexicons) > 0 && remainder != ''
        then self.lex(remainder, endLineNr, endColumnNr, prev + lexicons)
        else []
      ),
}
