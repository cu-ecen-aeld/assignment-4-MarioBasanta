##############################################################
#
# AESD-ASSIGNMENTS
#
##############################################################

# Commit hash of your assignment 4 repo to build
# i had to use repo 4 because i did the assignment 4.1 at this repository.
AESD_ASSIGNMENTS_VERSION = 'f20ad57c0d1428d91cb403219444cefb823b9ded'

# SSH Git repository URL for my assignment 4.1 repo
AESD_ASSIGNMENTS_SITE = 'git@github.com:MarioBasanta/assignments-3-and-later-MarioBasanta.git'
AESD_ASSIGNMENTS_SITE_METHOD = git
AESD_ASSIGNMENTS_GIT_SUBMODULES = YES

# Build commands: build finder-app via Makefile
define AESD_ASSIGNMENTS_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)/finder-app all
endef

# Install commands: install configs, executables, and autotest scripts
define AESD_ASSIGNMENTS_INSTALL_TARGET_CMDS
	# Create directory for config files
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/etc/finder-app/conf/
	# Copy config files
	$(INSTALL) -m 0755 $(@D)/conf/* $(TARGET_DIR)/etc/finder-app/conf/

	# Install test scripts for autotest
	$(INSTALL) -m 0755 $(@D)/assignment-autotest/test/assignment4/* $(TARGET_DIR)/bin

	# Install main executables and scripts to /bin
	$(INSTALL) -m 0755 $(@D)/finder-app/writer.sh $(TARGET_DIR)/bin
	$(INSTALL) -m 0755 $(@D)/finder-app/writer $(TARGET_DIR)/bin
	$(INSTALL) -m 0755 $(@D)/finder-app/finder.sh $(TARGET_DIR)/bin
	$(INSTALL) -m 0755 $(@D)/finder-app/finder-test.sh $(TARGET_DIR)/bin
endef

$(eval $(generic-package))

