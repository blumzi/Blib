all:

install: TOP = $(shell [[ "$${DESTDIR}" == *BUILDROOT* ]] && echo $${DESTDIR} || echo $${DESTDIR}/$${BLIB_BASE} )
install:
	install -m 644 -D profile.d/blib.sh ${TOP}/etc/profile.d/blib.sh
	install -m 644 -D bash_env.sh ${TOP}/etc/bash_env.sh

.PHONY: install
