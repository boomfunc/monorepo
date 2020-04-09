# This Makefile describes global git options and git shortcuts.


# Tell git to use ssh clone instead https (for private repos).
# Workaround with invoking at initialization stage of this Makefile.
GITHUB_REWRITE := $(shell git config --global url.git@github.com:.insteadOf https://github.com/)
BOOMFUNC_GITEA_REWRITE := $(shell git config --global url.gitea@git.boomfunc.io:.insteadOf https://gitea.boomfunc.io/)
