TARGET := iphone:clang:14.5:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TGExtra

TGExtra_FILES = $(shell find Sources \( -name '*.swift' -o -name '*.m' -o -name '*.xm' \))

TGExtra_SWIFTFLAGS = -ISources/tgapiC/include
TGExtra_CFLAGS = -fobjc-arc -ISources/tgapiC/include -Wno-deprecated-declarations
TGExtra_FRAMEWORKS = CoreServices
TGExtra_LOGOS_DEFAULT_GENERATOR = internal

TGExtra_RESOURCE_FILES = Sources/tgapi/Resources

# Copy TGExtra.bundle manually during the packaging step
after-stage::
	@echo ">>> Copying Choco.bundle into .deb package..."
	@mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support
	@cp -a TGExtra.bundle $(THEOS_STAGING_DIR)/Library/Application\ Support/
	
include $(THEOS_MAKE_PATH)/tweak.mk