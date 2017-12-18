BINS = btool \
		colors/show \
		commands/show \
		module/show \
		object/configure \
		object/delete \
		object/show \
		platform/dmi/show

include ../distrib/${DISTRO}/macros.mk

install:
ifeq ($(STAGING_AREA),)
	$(error Missing STAGING_AREA)
endif
	$(foreach bin,${BINS},install -m 755 -D ${bin} $(STAGING_AREA)/usr/share/$(PACKAGE_NAME)/bin/${bin};)
