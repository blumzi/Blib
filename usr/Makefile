MANS = man1/btool.1 \
		man3/blib.3 \
		man5/blib-guidelines.5

include ../distrib/${DISTRO}/macros.mk

install: TOP = $(shell [[ "$${DESTDIR}" == *BUILDROOT* ]] && echo $${DESTDIR} || echo $${DESTDIR}/$${BLIB_BASE} )
install:
	$(foreach man, ${MANS}, \
		install -m 644 -D share/man/${man} ${TOP}/usr/share/man/${man}; \
	)
