# This Makefile describes the behavior of a node that was handling by node and npm.
include $(ROOT)/.make/git.mk


# Get the npm bin path.
NPM := $(shell which npm)


.PHONY: npm-install
npm-install:
	#### Node( '$(NODE)' ).Call( '$@' )
	$(NPM) install


# Performance section. Testing, benchmarking, profiling, tracing, debugging, etc.
.PHONY: npm-test
npm-test: npm-install
	#### Node( '$(NODE)' ).Call( '$@' )
	$(NPM) test


# Build and run section. Convert source code to executable and provide process.
# Provide multiple options for building (bin, lib, etc).

# Calculate build variables.
TIMESTAMP := $(shell date +%s)


.PHONY: npm-build
npm-build: npm-install
	$(NPM) run build


.PHONY: npm-export
npm-export: npm-install
	$(NPM) run export
