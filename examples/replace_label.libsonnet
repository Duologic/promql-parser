local parser = import '../parser.libsonnet';
local promqlschema = import '../schema.libsonnet';

{
  query:
    |||
      abs(
        avg(limit_ratio(0.5, http_requests_total{namespace="abc"}))
        -
        avg(limit_ratio(-0.5, http_requests_total{status="true"}))
      ) <= bool stddev(http_requests_total{namespace="abc"})
    |||,

  parsed:: parser.new(self.query).parse(),

  local deepMap(func, x) =
    if std.isObject(x)
    then std.mapWithKey(function(_, y) deepMap(func, func(y)), func(x))
    else if std.isArray(x)
    then std.map(function(y) deepMap(func, func(y)), x)
    else func(x),

  local removeNamespaceLabel(selector) =
    if std.isObject(selector) && std.get(selector, 'type', '') == 'vector_selector'
    then
      selector
      + {
        matchers: [
          label
          for label in selector.matchers
          if label.key != 'namespace'
        ],
      }
    else selector,

  removed:
    promqlschema.objectToString(
      deepMap(
        removeNamespaceLabel,
        self.parsed,
      ),
    ),

  output: 'Original:\n\n' + self.query + '\n\nWithout namespace label:\n\n' + self.removed,
}.output
