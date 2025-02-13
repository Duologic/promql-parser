local queries =
  [
    @'"abc"',
    '`abc`',
    "'abc'",
    '23',
    '-2.43',
    '3.4e-9',
    '0x8f',
    '-Inf',
    'NaN',
    '1_000_000',
    '.123_456_789',
    '0x_53_AB_F3_82',
    '1s',
    '2m',
    '1ms',
    '-2h',
    '1h30m',
    '12h34m56s',
    '54s321ms',
    //'0xABm # INVALID',
    //'0xA0m # INVALID',
    //'1.5h # INVALID',
    //'+Infd # INVALID as time, valid identifier',
    'http_requests_total',
    'http_requests_total[1m]',
    'http_requests_total{}',
    'sum{}',
    'http_requests_total{job="prometheus",group="canary"}',
    'http_requests_total{environment=~"staging|testing|development",method!="GET"}',
    '{environment=~"staging|testing|development",method!="GET"}',
    ////'on{} # INVALID',
    'http_requests_total{job="prometheus"}[5m]',
    'http_requests_total{} offset 5m',
    'http_requests_total{} @ 1609746000',
    'http_requests_total{} offset 5m @ 1609746000',
    'http_requests_total offset 5m',
    'sum(http_requests_total{method="GET"} offset 5m)',
    //'sum(http_requests_total{method="GET"}) offset 5m # INVALID.',
    'rate(http_requests_total[5m] offset 1w)',
    'rate(http_requests_total[5m] offset -1w)',
    'http_requests_total @ 1609746000',
    'sum(http_requests_total{method="GET"} @ 1609746000) # GOOD',
    //'sum(http_requests_total{method="GET"}) @ 1609746000 # INVALID',
    'rate(http_requests_total[5m] @ 1609746000)',
    'http_requests_total @ 1609746000 offset 5m',
    'http_requests_total offset 5m @ 1609746000',
    'http_requests_total @ start()',
    'rate(http_requests_total[5m] @ end())',
    'rate(http_requests_total[5m] @ end()) + rate(http_requests_total[5m] @ end())',
    'rate(http_requests_total[5m] @ end()) + on() rate(http_requests_total[5m] @ end())',
    'method_code:http_errors:rate5m{code="500"} / ignoring(code) method:http_requests:rate5m',
    'method_code:http_errors:rate5m / ignoring(code) group_left method:http_requests:rate5m',
    'method_code:http_errors:rate5m / ignoring(code) group_left(status) method:http_requests:rate5m',
    'sum without (instance) (http_requests_total)',
    'sum by (application, group) (http_requests_total)',
    'sum(http_requests_total)',
    //'sum(5, http_requests_total) # INVALID',
    'count_values("version", build_version)',
    'topk(5, http_requests_total)',
    //'topk(http_requests_total) # INVALID',
    'limitk(10, http_requests_total)',
    'limit_ratio(0.1, http_requests_total)',
    'limit_ratio(-0.9, http_requests_total)',
    //'http_requests_total{} and bool random{} # INVALID',
    |||
      abs(
        avg(limit_ratio(0.5, http_requests_total))
        -
        avg(limit_ratio(-0.5, http_requests_total))
      ) <= bool stddev(http_requests_total)
    |||,
  ];

local parser = import './parser.libsonnet';
std.map(function(q) parser.new(q).parse(), queries)
