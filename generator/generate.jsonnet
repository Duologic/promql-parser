local generator = import 'github.com/crdsonnet/astsonnet/generator/generate.jsonnet';
local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';

local schema = import '../schema.libsonnet';

local docstring =
  d.package.new(
    'promql-libsonnet',
    'github.com/Duologic/promql-parser',
    'Jsonnet library to generate promQL.',
    'main.libsonnet',
    'main',
  );

generator(schema, docstring)
