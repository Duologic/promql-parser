local promql = import './gen.libsonnet';
local parser = import './parser.libsonnet';

{
  input:
    promql.vector_selector.new()
    + promql.vector_selector.withName('up')
    + promql.vector_selector.withMatchers(
      promql.label_matcher.new('namespace', 'default', '=')
    ),

  input_render: self.input.toString(),

  parsed: parser.new(self.input_render).parse(),
}
