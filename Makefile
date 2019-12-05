# We use global GRAPH interface.
#
# 1) NODE is a NODE only if it has a Makefile. It will be NODE's root path.
# 2) NODE may have `dist` directory (means directory may be deployed to somewhere and ONLY content of this directory might be deployed).
# 3) Each NODE's Makefile must implement at least targets below:
# - lint
# - test
# - publish
#
# Current Makefile is just proxy part and entrypoint for GRAPH as a NODE.
# Means also implements interface described above.
#
# The only variables required for working is:
# 1) Root of the GRAPH (current path).
# 2) NODE's path (path to directory containing NODE's Makefile)
# 3) NODE's basename. Used for naming convetion and dist naming.
#
# NODE variable defined from somewhere (cli options, env variables, etc) means
# that we work with concrete NODE, just proxy targets to their Makefile.
# Otherwise we work with GRAPH as a NODE. This means, we must get the list of NODES
# and proxy targets to each og them.


# Define root of the graph immediately.
ROOT := $(CURDIR)


# Define base function to render NODE's target recipe.
# This recipe is proxy that just invoke same make from the NODE's root directory.
# NOTE: function have 'lazy' definition (recalculates each time).
# NOTE: because it is recipe template each line (including last empty line) is very important!
define NODE_PROXY_TARGET_RECIPE
	###################################
	#### Node( '$(1)' ).Call( '$@' )
	@$(MAKE) \
		ROOT=$(ROOT) \
		NODE=$(1) \
		BASE=$(shell basename $(realpath $(1))) \
			-C $(1) $@
	###################################

endef


# Define variable for calculating nested NODEs.
# Find only in source code, omit NODEs `tmp` and `dist` directories.
# Also omit current Makefile.
# NOTE: variable is lazy (recalculates each time).
MAKEFILE_SOURCE_FILES = $(shell \
	find . \
		-type f \
		-path './*/Makefile' \
		-not -path '*/tmp/*' \
		-not -path '*/dist/*' \
)


# $(FORMAT_ROOTS) is the lazy function to calculate formatted nodes roots.
# How we get them:
# 1) Drop Makefile part if exists.
# 2) Drop trailing slash if exists.
# 3) Drop leading slash if exists.
# 4) Sort the words of list in lexical order, removing duplicate words.
#    Incidentally, since sort removes duplicate words, you can use it for this purpose.
#    Even if you don’t care about the sort order.
FORMAT_ROOTS = $(sort \
	$(patsubst ./%, %, \
		$(patsubst %/, %, \
			$(patsubst %/Makefile, %, $(1)) \
		) \
	) \
)


# $(SHELL_SORT_REVERSE_BY_LEN) is the lazy function shell pattern to sort incoming list by length in reverse order.
define SHELL_SORT_REVERSE_BY_LEN
	echo '$(1)' | \
	xargs -n1 | \
	awk '{ print length($$0), $$0 }' | \
	sort -rn | \
	cut -d' ' -f2- | \
	xargs
endef


# $(SHELL_SMART_ROOTS) is the lazy function shell pattern used to calculate nearest NODE roots for specified paths.
# Actually - get first longest prefix from $(2) applied to each from $(1).
# We convert $(2) (roots) to sorted in reverse order.
define SHELL_SMART_ROOTS
	for path in $(1); do \
		for root in $(shell $(call SHELL_SORT_REVERSE_BY_LEN,$(2))); do \
			case $${path} in \
				$${root}*) \
					printf '%s ' $$root; \
					break 1 ;; \
			esac \
		done \
	done
endef


# This section calculates for which nodes session was started.
# There are some mods:
# 1) NODE set from cli. Session run for: [$(NODE)].
# 2) NODE not set. Use all graph as list of NODEs. Session run for: [node1, node2, ... ].
# 3) Calculate changed only nodes from any VCS and use this list. TODO
#
# $(DIFF) is the space delimited unformatted changed parts of the graph.
# May be one of the following formats:
# 1) ./foo/bar
# 2) foo/bar
# 3) ./foo/bar/
# 4) foo/bar/
# 5) ./foo/bar/Makefile
# 6) foo/bar/Makefile
# At this stage - $(DIFF) is unformatted and may be invalid or broken.
ifeq ($(DIFF),)
	# Whole GRAPH as a NODE.
	# Calculate all nested nodes and use this list to iterate over.
	override DIFF := $(MAKEFILE_SOURCE_FILES)
endif


# $(SESSION) are the roots of the nodes to which 'make' will be applied.
# There are two possible running modes: SMART and STUPID.
ifeq ($(DIFF_MOD),SMART)
	# SMART gets same paths, but calcultes to which nodes this paths corresponds to.
	SESSION := $(call \
		FORMAT_ROOTS,\
		$(shell $(call SHELL_SMART_ROOTS,\
			$(call FORMAT_ROOTS,$(DIFF)),\
			$(call FORMAT_ROOTS,$(MAKEFILE_SOURCE_FILES))\
		))\
	)
else
	# STUPID gets some paths from $(DIFF), format them and try to get Makefiles.
	SESSION := $(call FORMAT_ROOTS,$(DIFF))
endif


# $(SESSION_MAKEFILES) is used to determine that NODE's Makefiles in $(SESSION) really exists.
# This variable will be used as dependency in targets.
# Just add Makefile suffix to root.
SESSION_MAKEFILES := $(addsuffix /Makefile, $(SESSION))


# Target to watch the $(SESSION) hierarchical tree.
# Also used as default targe because this is first target in Makefile.
.PHONY: session
session:
	@echo $(SESSION)


# Global interface targets.
.PHONY: lint test publish
lint test publish: $(SESSION_MAKEFILES)
	$(foreach\
		NODE,\
		$(SESSION),\
		$(call NODE_PROXY_TARGET_RECIPE,$(NODE))\
	)


# $(SHELL_RUN_TEST) is the lazy testing function which fail with status code 1 if `make session` with provided variables $(1) have output different from expected $(2)
define SHELL_RUN_TEST
	if [ '$(shell $(MAKE) $(1) session)' != '$(2)' ]; then \
		echo 'Failed'; \
		exit 1; \
	else \
		echo 'Success'; \
	fi;
endef


# Targets for self testing purpose.
.PHONY: selftest
selftest:
	# STUPID cases. Covers different DIFF formats.
	@$(call SHELL_RUN_TEST,DIFF_MOD=STUPID MAKEFILE_SOURCE_FILES='foo foo/bar' DIFF='',foo foo/bar) # Empty diff - use whole graph.
	@$(call SHELL_RUN_TEST,DIFF_MOD=STUPID MAKEFILE_SOURCE_FILES='foo foo/bar' DIFF='./foo/bar',foo/bar)
	@$(call SHELL_RUN_TEST,DIFF_MOD=STUPID MAKEFILE_SOURCE_FILES='foo foo/bar' DIFF='foo/bar',foo/bar)
	@$(call SHELL_RUN_TEST,DIFF_MOD=STUPID MAKEFILE_SOURCE_FILES='foo foo/bar' DIFF='./foo/bar/',foo/bar)
	@$(call SHELL_RUN_TEST,DIFF_MOD=STUPID MAKEFILE_SOURCE_FILES='foo foo/bar' DIFF='foo/bar/',foo/bar)
	@$(call SHELL_RUN_TEST,DIFF_MOD=STUPID MAKEFILE_SOURCE_FILES='foo foo/bar' DIFF='./foo/bar/Makefile',foo/bar)
	@$(call SHELL_RUN_TEST,DIFF_MOD=STUPID MAKEFILE_SOURCE_FILES='foo foo/bar' DIFF='foo/bar/Makefile',foo/bar)
	# SMART cases. Covers dynamic calculating.
	@$(call SHELL_RUN_TEST,DIFF_MOD=SMART MAKEFILE_SOURCE_FILES='foo foo/bar foo/bar/baz lol' DIFF='',foo foo/bar foo/bar/baz lol) # Empty diff - use whole graph.
	@$(call SHELL_RUN_TEST,DIFF_MOD=SMART MAKEFILE_SOURCE_FILES='foo foo/bar foo/bar/baz lol' DIFF='foo/1 foo/2 foo/bar/baz/3/4/5 foo/bar/baz/3/5 lol/kek/f lol/kek/f2 lol/f3',foo foo/bar/baz lol)
