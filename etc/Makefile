all:

install:
ifeq ($(STAGING_AREA),)
	$(error Missing STAGING_AREA)
endif
	install -m 644 -D profile.d/blib.sh $(STAGING_AREA)/usr/share/blib/etc/profile.d/blib.sh
	install -m 644 -D bash_env.sh $(STAGING_AREA)/usr/share/blib/etc/bash_env.sh

.PHONY: install
