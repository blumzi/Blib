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
	$(foreach bin,${BINS},install -m 755 -D ${bin} ${DESTDIR}/${BLIB_BASE}/bin/${bin};)
