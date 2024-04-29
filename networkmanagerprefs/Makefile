include $(THEOS)/makefiles/common.mk

export TARGET = iphone:clang:11.2:11.0
export ARCHS = arm64 arm64e
export VERSION = $(shell grep '^Version:' ../control | cut -d: -f2- | tr -d ' ')

BUNDLE_NAME = NetworkManagerPrefs

NetworkManagerPrefs_FILES = CCNMRootListController.m
NetworkManagerPrefs_INSTALL_PATH = /Library/PreferenceBundles
NetworkManagerPrefs_FRAMEWORKS = UIKit
NetworkManagerPrefs_PRIVATE_FRAMEWORKS = Preferences
NetworkManagerPrefs_CFLAGS = -fobjc-arc

NetworkManagerPrefs_CFLAGS += -DNETWORK_MANAGER_VERSION=\"$(VERSION)\"

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	@echo "Version: $(VERSION)"
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NetworkManagerPrefs.plist$(ECHO_END)
