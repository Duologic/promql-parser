gen.libsonnet: generator/generate.jsonnet
	jrsonnet -S -J generator/vendor generator/generate.jsonnet | jsonnetfmt - > gen.libsonnet

.PHONY: test
test:
	jrsonnet -J vendor test.libsonnet

examples/replace_label.libsonnet.output: examples/replace_label.libsonnet
	jrsonnet -S -J vendor examples/replace_label.libsonnet > examples/replace_label.libsonnet.output
