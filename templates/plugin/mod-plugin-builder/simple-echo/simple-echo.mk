######################################
#
# simple-echo  (path B package file)
#
# Builds the plugin from a GitHub repo at a given commit. Upload this file at
# https://builder.mod.audio/buildroot for an install link, or put it in
# mod-plugin-builder at plugins/package/simple-echo/simple-echo.mk.
#
# 1. Replace OWNER and REPO with your GitHub user and repository.
#    DPF is a git submodule at dpf/ (tools/add_dpf_submodule.sh); the hook below
#    fetches it, as MOD's own packages do.
# 2. Push, then set SIMPLE_ECHO_VERSION to the FULL 40-character commit hash
#    (GitHub: Commits -> copy button, or `git rev-parse HEAD`).
# The filename must match the variable prefix: simple-echo.mk -> SIMPLE_ECHO_.
#
######################################

SIMPLE_ECHO_VERSION = COMMIT_HASH_HERE
SIMPLE_ECHO_SITE = https://github.com/OWNER/REPO.git
SIMPLE_ECHO_SITE_METHOD = git
SIMPLE_ECHO_GIT_SUBMODULES = y
SIMPLE_ECHO_BUNDLES = simple-echo.lv2

# fetch git submodules (DPF), as MOD's own packages do (mod-plugin-builder)
SIMPLE_ECHO_PRE_DOWNLOAD_HOOKS += MOD_PLUGIN_BUILDER_DOWNLOAD_WITH_SUBMODULES

SIMPLE_ECHO_TARGET_MAKE = $(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) NOOPT=true -C $(@D)

define SIMPLE_ECHO_BUILD_CMDS
	$(SIMPLE_ECHO_TARGET_MAKE)
endef

define SIMPLE_ECHO_INSTALL_TARGET_CMDS
	$(SIMPLE_ECHO_TARGET_MAKE) install DESTDIR=$(TARGET_DIR) PREFIX=/usr
endef

$(eval $(generic-package))
