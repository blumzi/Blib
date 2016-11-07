MANS = share/man/man1/bdoc.1 \
		share/man/man1/btool.1 \
		share/man/man3/blib.3 \
		share/man/man5/bdoc-guidelines.5 \
		share/man/man5/blib-guidelines.5

install:
	$(foreach man, ${MANS}, \
		install -m 644 -D ${man} ${DESTDIR}/usr/${man}; \
	)
