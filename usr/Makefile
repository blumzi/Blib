MANS = man1/btool.1 \
		man3/blib.3 \
		man5/blib-guidelines.5

DOCS = copyright changelog

include ../distrib/${DISTRO}/macros.mk

install:
ifeq ($(STAGING_AREA),)
	$(error Missing STAGING_AREA)
endif
	$(foreach man, ${MANS}, \
		install -m 644 -D share/man/${man} ${STAGING_AREA}/usr/share/man/${man}; \
		gzip --best --force -n ${STAGING_AREA}/usr/share/man/${man}; \
	)
	$(foreach doc, ${DOCS}, \
		install -m 644 -D share/doc/blib/${doc} ${STAGING_AREA}/usr/share/doc/blib/${doc}; \
	)
	gzip --best --force -n ${STAGING_AREA}/usr/share/doc/blib/changelog
