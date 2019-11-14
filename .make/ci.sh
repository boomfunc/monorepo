#!/bin/sh
set -eu


# Shell script used as entrypoin for CI/CD pipelines.
# Calculates diff from VCS and use SMART node detection mode from root Makefile.


# Define git commits range.
GIT_COMMIT_FROM='d9061bf69dcb27bf82096652c9984771541821cc'
GIT_COMMIT_TO='787dbac21c4ba25d69366f0bf944649a489b84ce'


# Calculate diff from git.
# For gnumake session we need only changed filenames.
GIT_DIFF=`git diff --name-only ${GIT_COMMIT_FROM}...${GIT_COMMIT_TO}`


echo '================================================================================'
echo "git diff --name-only ${GIT_COMMIT_FROM}...${GIT_COMMIT_TO}"
echo ${GIT_DIFF}
echo '================================================================================'


# Run smart diff detection.
DIFF_MOD=SMART DIFF=${GIT_DIFF} .make/make.sh $@
