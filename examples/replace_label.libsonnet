local parser = import '../parser.libsonnet';
local promqlschema = import '../schema.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  query:
    |||
      abs(
        avg(limit_ratio(0.5, http_requests_total{${var}, namespace="abc"}))
        -
        avg(limit_ratio(-0.5, http_requests_total{status="true"}))
      ) <= bool stddev(http_requests_total{namespace="abc"})
    |||,

  parsed:: parser.new(self.query).parse(),

  local removeNamespaceLabel(selector) =
    if std.isObject(selector) && std.get(selector, 'type', '') == 'vector_selector'
    then
      selector
      + {
        matchers: [
          label
          for label in selector.matchers
          if std.get(label, 'key') != 'namespace'
        ],
      }
    else selector,

  removed:
    promqlschema.objectToString(
      xtd.inspect.deepMap(
        removeNamespaceLabel,
        self.parsed,
      ),
    ),

  output: 'Original:\n\n' + self.query + '\n\nWithout namespace label:\n\n' + self.removed,
}.output
