gen.libsonnet:
	jrsonnnet -J generator/vendor generator/generate.jsonnet | jsonnetfmt - > gen.libsonnet

.PHONY: test
test:
	jrsonnet -J vendor test.libsonnet
