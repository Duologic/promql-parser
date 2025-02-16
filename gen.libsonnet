// DO NOT EDIT: generated by generator/generate.jsonnet
local astschema = import './schema.libsonnet',
      withToStringFunction() = {
  toString():: astschema.objectToString(self),
};
{
  '#': {
    filename: 'main.libsonnet',
    help: 'Jsonnet library to generate promQL.\n## Install\n\n```\njb install github.com/Duologic/promql-parser@main\n```\n\n## Usage\n\n```jsonnet\nlocal promql-libsonnet = import "github.com/Duologic/promql-parser/main.libsonnet"\n```\n',
    'import': 'github.com/Duologic/promql-parser/main.libsonnet',
    installTemplate: '\n## Install\n\n```\njb install %(url)s@%(version)s\n```\n',
    name: 'promql-libsonnet',
    url: 'github.com/Duologic/promql-parser',
    usageTemplate: '\n## Usage\n\n```jsonnet\nlocal %(name)s = import "%(import)s"\n```\n',
    version: 'main',
  },
  aggregate+:
    {
      '#new': { 'function': { args: [{ default: null, enums: ['sum', 'min', 'max', 'avg', 'group', 'stddev', 'stdvar', 'count', 'count_values', 'bottomk', 'topk', 'quantile', 'limitk', 'limit_ratio'], name: 'operator', type: 'string' }, { default: null, enums: null, name: 'expr', type: 'object' }], help: '' } },
      new(operator, expr):
        self.withType()
        + withToStringFunction()
        + self.withOperator(operator)
        + self.withExpr(expr),
      '#withExpr': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
      withExpr(value): {
        expr: value,
      },
      '#withExprMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
      withExprMixin(value): {
        expr+: value,
      },
      '#withGrouping': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withGrouping(value): {
        grouping:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withGroupingMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withGroupingMixin(value): {
        grouping+:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withOperator': { 'function': { args: [{ default: null, enums: ['sum', 'min', 'max', 'avg', 'group', 'stddev', 'stdvar', 'count', 'count_values', 'bottomk', 'topk', 'quantile', 'limitk', 'limit_ratio'], name: 'value', type: ['string'] }], help: '' } },
      withOperator(value): {
        operator: value,
      },
      '#withParam': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
      withParam(value): {
        param: value,
      },
      '#withParamMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
      withParamMixin(value): {
        param+: value,
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'aggregate',
      },
      '#withWithout': { 'function': { args: [{ default: true, enums: null, name: 'value', type: ['boolean'] }], help: '' } },
      withWithout(value=true): {
        without: value,
      },
    },
  binary+:
    {
      '#new': { 'function': { args: [{ default: null, enums: ['==', '!=', '>', '<', '>=', '<=', '+', '-', '*', '/', '%', '^', 'atan2', 'and', 'or', 'unless'], name: 'operator', type: 'string' }, { default: null, enums: null, name: 'lhs', type: 'object' }, { default: null, enums: null, name: 'rhs', type: 'object' }], help: '' } },
      new(operator, lhs, rhs):
        self.withType()
        + withToStringFunction()
        + self.withOperator(operator)
        + self.withLhs(lhs)
        + self.withRhs(rhs),
      '#withBool': { 'function': { args: [{ default: true, enums: null, name: 'value', type: ['boolean'] }], help: '' } },
      withBool(value=true): {
        bool: value,
      },
      '#withLhs': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
      withLhs(value): {
        lhs: value,
      },
      '#withLhsMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
      withLhsMixin(value): {
        lhs+: value,
      },
      '#withOperator': { 'function': { args: [{ default: null, enums: ['==', '!=', '>', '<', '>=', '<=', '+', '-', '*', '/', '%', '^', 'atan2', 'and', 'or', 'unless'], name: 'value', type: ['string'] }], help: '' } },
      withOperator(value): {
        operator: value,
      },
      '#withRhs': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
      withRhs(value): {
        rhs: value,
      },
      '#withRhsMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
      withRhsMixin(value): {
        rhs+: value,
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'binary',
      },
      '#withVectorMatching': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withVectorMatching(value): {
        vector_matching: value,
      },
    },
  duration+:
    {
      '#new': { 'function': { args: [{ default: null, enums: null, name: 'duration', type: 'string' }], help: '' } },
      new(duration):
        self.withType()
        + withToStringFunction()
        + self.withDuration(duration),
      '#withDuration': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withDuration(value): {
        duration: value,
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'duration',
      },
    },
  functioncall+:
    {
      '#new': { 'function': { args: [{ default: null, enums: null, name: 'func', type: 'string' }], help: '' } },
      new(func):
        self.withType()
        + withToStringFunction()
        + self.withFunc(func),
      '#withArgs': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withArgs(value): {
        args:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withArgsMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withArgsMixin(value): {
        args+:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withFunc': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withFunc(value): {
        func: value,
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'functioncall',
      },
    },
  group_modifier+:
    {
      '#new': { 'function': { args: [{ default: null, enums: ['group_left', 'group_right'], name: 'group_modifier', type: 'string' }], help: '' } },
      new(group_modifier):
        self.withType()
        + withToStringFunction()
        + self.withGroupModifier(group_modifier),
      '#withGroupModifier': { 'function': { args: [{ default: null, enums: ['group_left', 'group_right'], name: 'value', type: ['string'] }], help: '' } },
      withGroupModifier(value): {
        group_modifier: value,
      },
      '#withMatchingLabels': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withMatchingLabels(value): {
        matching_labels:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withMatchingLabelsMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withMatchingLabelsMixin(value): {
        matching_labels+:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'group_modifier',
      },
    },
  label_matcher+:
    {
      '#new': { 'function': { args: [{ default: null, enums: null, name: 'key', type: 'string' }, { default: null, enums: null, name: 'value', type: 'string' }, { default: null, enums: null, name: 'operator', type: 'string' }], help: '' } },
      new(key, value, operator):
        self.withType()
        + withToStringFunction()
        + self.withKey(key)
        + self.withValue(value)
        + self.withOperator(operator),
      '#withKey': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withKey(value): {
        key: value,
      },
      '#withOperator': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withOperator(value): {
        operator: value,
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'label_matcher',
      },
      '#withValue': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withValue(value): {
        value: value,
      },
    },
  number+:
    {
      '#new': { 'function': { args: [{ default: null, enums: null, name: 'number', type: 'number' }], help: '' } },
      new(number):
        self.withType()
        + withToStringFunction()
        + self.withNumber(number),
      '#withNumber': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['number'] }], help: '' } },
      withNumber(value): {
        number: value,
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'number',
      },
    },
  string+:
    {
      '#new': { 'function': { args: [{ default: null, enums: null, name: 'string', type: 'string' }], help: '' } },
      new(string):
        self.withType()
        + withToStringFunction()
        + self.withString(string),
      '#withString': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withString(value): {
        string: value,
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'string',
      },
    },
  vector_matching+:
    {
      '#new': { 'function': { args: [{ default: null, enums: ['on', 'ignoring'], name: 'vector_matching', type: 'string' }, { default: null, enums: null, name: 'matching_labels', type: 'array' }], help: '' } },
      new(vector_matching, matching_labels):
        self.withType()
        + withToStringFunction()
        + self.withVectorMatching(vector_matching)
        + self.withMatchingLabels(matching_labels),
      '#withGroupModifier': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withGroupModifier(value): {
        group_modifier: value,
      },
      '#withMatchingLabels': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withMatchingLabels(value): {
        matching_labels:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withMatchingLabelsMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withMatchingLabelsMixin(value): {
        matching_labels+:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'vector_matching',
      },
      '#withVectorMatching': { 'function': { args: [{ default: null, enums: ['on', 'ignoring'], name: 'value', type: ['string'] }], help: '' } },
      withVectorMatching(value): {
        vector_matching: value,
      },
    },
  vector_selector+:
    {
      '#new': { 'function': { args: [], help: '' } },
      new():
        self.withType()
        + withToStringFunction(),
      '#withMatchers': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withMatchers(value): {
        matchers:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withMatchersMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['array'] }], help: '' } },
      withMatchersMixin(value): {
        matchers+:
          (if std.isArray(value)
           then value
           else [value]),
      },
      '#withName': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withName(value): {
        name: value,
      },
      '#withOffset': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string', 'string'] }], help: '' } },
      withOffset(value): {
        offset: value,
      },
      '#withOffsetMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string', 'string'] }], help: '' } },
      withOffsetMixin(value): {
        offset+: value,
      },
      offset+:
        {
          '#withNumber': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
          withNumber(value): {
            offset+: {
              number: value,
            },
          },
          '#withDuration': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
          withDuration(value): {
            offset+: {
              duration: value,
            },
          },
        },
      '#withRange': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string', 'string'] }], help: '' } },
      withRange(value): {
        range: value,
      },
      '#withRangeMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string', 'string'] }], help: '' } },
      withRangeMixin(value): {
        range+: value,
      },
      range+:
        {
          '#withNumber': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
          withNumber(value): {
            range+: {
              number: value,
            },
          },
          '#withDuration': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
          withDuration(value): {
            range+: {
              duration: value,
            },
          },
        },
      '#withStartEnd': { 'function': { args: [{ default: null, enums: ['start', 'end'], name: 'value', type: ['string'] }], help: '' } },
      withStartEnd(value): {
        start_end: value,
      },
      '#withTimestamp': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string', 'string'] }], help: '' } },
      withTimestamp(value): {
        timestamp: value,
      },
      '#withTimestampMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string', 'string'] }], help: '' } },
      withTimestampMixin(value): {
        timestamp+: value,
      },
      timestamp+:
        {
          '#withNumber': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
          withNumber(value): {
            timestamp+: {
              number: value,
            },
          },
          '#withDuration': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
          withDuration(value): {
            timestamp+: {
              duration: value,
            },
          },
        },
      '#withType': { 'function': { args: [], help: '' } },
      withType(): {
        type: 'vector_selector',
      },
    },
}
