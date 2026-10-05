######################################
#
# simple-echo  (path B package file)
#
# Builds the plugin from a GitHub repo at a given commit. Upload this file at
# https://builder.mod.audio/buildroot for an install link, or put it in
# mod-plugin-builder at plugins/package/simple-echo/simple-echo.mk.
#
# 1. Replace OWNER and REPO with your GitHub user and repository.
# 2. Push, then set SIMPLE_ECHO_VERSION to the FULL 40-character commit hash
#    (GitHub: Commits -> copy button, or `git rev-parse HEAD`).
# The filename must match the variable prefix: simple-echo.mk -> SIMPLE_ECHO_.
#
######################################

SIMPLE_ECHO_VERSION = COMMIT_HASH_HERE
SIMPLE_ECHO_SITE = $(call github,OWNER,REPO,$(SIMPLE_ECHO_VERSION))
SIMPLE_ECHO_BUNDLES = simple-echo.lv2

SIMPLE_ECHO_TARGET_MAKE = $(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) NOOPT=true -C $(@D)

define SIMPLE_ECHO_BUILD_CMDS
	$(SIMPLE_ECHO_TARGET_MAKE)
endef

define SIMPLE_ECHO_INSTALL_TARGET_CMDS
	$(SIMPLE_ECHO_TARGET_MAKE) install DESTDIR=$(TARGET_DIR) PREFIX=/usr
endef

$(eval $(generic-package))
