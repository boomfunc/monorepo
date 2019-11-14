#!/bin/sh
set -eu


# The only target cannot be resolved by make - GNUmake itself.
# Main idea - we dont know where `make` session was invoked.
# Maybe there is not GNUmake installed. Detect system, package manager and install it.
if ! [ -x "$(command -v make)" ]
then
	# https://unix.stackexchange.com/questions/46081/identifying-the-system-package-manager
	echo 'make AUTO INSTALL NOT IMPLEMENTED. COMING SOON.'
	exit 1
fi


# Get required variables for running make session from caller.
readonly DIFF
readonly DIFF_MOD


echo '================================================================================'
make --version
echo '================================================================================'


# Make installed, just forward request to his binary.
make DIFF_MOD="${DIFF_MOD}" DIFF="${DIFF}" $@
