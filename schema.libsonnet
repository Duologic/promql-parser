{
  local root = self,
  objectToString(obj):: root['$defs'][obj.type].toString(obj),

  '$defs': {
    string: {
      type: 'object',
      properties: {
        type: { const: 'string' },
        string: { type: 'string' },
      },
      required: ['string'],
      toString(obj)::
        std.toString(obj.string),
    },
    number: {
      type: 'object',
      properties: {
        type: { const: 'number' },
        number: { type: 'number' },
      },
      required: ['number'],
      toString(obj)::
        std.toString(obj.number),
    },
    duration: {
      type: 'object',
      properties: {
        type: { const: 'duration' },
        duration: { type: 'string' },
      },
      required: ['duration'],
      toString(obj)::
        std.toString(obj.duration),
    },
    vector_selector: {
      type: 'object',
      properties: {
        type: { const: 'vector_selector' },
        name: { type: 'string' },
        matchers: { type: 'array', items: { '$ref': '#/$defs/label_matcher' } },
        range: {
          oneOf: [
            { '$ref': '#/$defs/number' },
            { '$ref': '#/$defs/duration' },
          ],
        },
        offset: {
          oneOf: [
            { '$ref': '#/$defs/number' },
            { '$ref': '#/$defs/duration' },
          ],
        },
        timestamp: {
          oneOf: [
            { '$ref': '#/$defs/number' },
            { '$ref': '#/$defs/duration' },
          ],
        },
        start_end: {
          type: 'string',
          enum: ['start', 'end'],
        },
      },
      required: [/* ??? */],
      toString(obj)::
        std.get(obj, 'name', '')
        + (if 'matchers' in obj then '{' else '')
        + std.join(', ', [
          root.objectToString(matcher)
          for matcher in std.get(obj, 'matchers', [])
        ])
        + (if 'matchers' in obj then '}' else '')
        + (if 'range' in obj
           then '[%s]' % root.objectToString(obj.range)
           else '')
        + (if 'offset' in obj
           then 'offset %s' % root.objectToString(obj.offset)
           else '')
        + (if 'timestamp' in obj
           then '@ %s' % root.objectToString(obj.timestamp)
           else if 'start_end' in obj
           then '@ %s' % root.objectToString(obj.start_end)
           else ''),
    },
    label_matcher: {
      type: 'object',
      properties: {
        type: { const: 'label_matcher' },
        key: { type: 'string' },
        value: { type: 'string' },
        operator: { type: 'string' },
      },
      required: ['key', 'value', 'operator'],
      toString(obj)::
        '`%(key)s`%(operator)s`%(value)s`' % obj,
    },
    binary: {
      type: 'object',
      properties: {
        type: { const: 'binary' },
        operator: {
          type: 'string',
          enum: [
            '==',
            '!=',
            '>',
            '<',
            '>=',
            '<=',
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
          ],
        },
        lhs: { type: 'object' },
        rhs: { type: 'object' },
        bool: { type: 'boolean' },
        vector_matching: { '$ref': '#/$defs/vector_matching' },
      },
      required: ['operator', 'lhs', 'rhs'],
      toString(obj)::
        std.join(' ', std.prune([
          root.objectToString(obj.lhs)
          + (if 'vector_matching' in obj
             then '\n'
             else ''),
          root.objectToString(obj.operator),
          (if std.get(obj, 'bool', false)
           then 'bool'
           else null),
          (if 'vector_matching' in obj
           then root.objectToString(obj.vector_matching) + '\n'
           else null),
          root.objectToString(obj.rhs),
        ])),
    },
    vector_matching: {
      type: 'object',
      properties: {
        type: { const: 'vector_matching' },
        vector_matching: { type: 'string', enum: ['on', 'ignoring'] },
        matching_labels: { type: 'array', items: { type: 'string' } },
        group_modifier: { '$ref': '#/$defs/group_modifier' },
      },
      required: ['vector_matching', 'matching_labels'],
      toString(obj)::
        std.toString(obj.keyword)
        + '('
        + std.join(', ', obj.matching_labels)
        + ')'
        + (if 'group_modifier' in obj
           then ' ' + root.objectToString(obj.group_modifier)
           else ''),
    },
    group_modifier: {
      type: 'object',
      properties: {
        type: { const: 'group_modifier' },
        group_modifier: { type: 'string', enum: ['group_left', 'group_right'] },
        matching_labels: { type: 'array', items: { type: 'string' } },
      },
      required: ['group_modifier'],
      toString(obj)::
        std.toString(obj.group_modifier)
        + (if 'matching_labels' in obj
           then
             '('
             + std.join(', ', obj.matching_labels)
             + ')'
           else ''),
    },
    functioncall: {
      type: 'object',
      properties: {
        type: { const: 'functioncall' },
        func: { type: 'string' },
        args: { type: 'array', items: { type: 'object' } },
      },
      required: ['func'],
      toString(obj)::
        std.toString(obj.func)
        + '('
        + std.join(', ', [
          root.objectToString(item)
          for item in std.get(obj, 'args', [])
        ])
        + ')',
    },
    aggregate: {
      type: 'object',
      properties: {
        type: { const: 'aggregate' },
        operator: {
          type: 'string',
          enum: [
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
        },
        expr: { type: 'object' },
        param: { type: 'object' },
        without: { type: 'boolean' },
        grouping: { type: 'array', items: { type: 'string' } },
      },
      required: ['operator', 'expr'],
      toString(obj)::
        std.toString(obj.operator)
        + (
          if 'grouping' in obj
          then
            ' '
            + (if std.get(obj, 'without', false)
               then 'without'
               else 'by')
            + '('
            + std.join(', ', obj.grouping)
            + ')'
          else ''
        )
        + '('
        + std.join(', ', std.prune([
          (if 'param' in obj
           then root.objectToString(obj.param)
           else null),
          root.objectToString(obj.expr),
        ]))
        + ')',
    },
  },
}
