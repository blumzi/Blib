RPMBUILD = $(HOME)/rpmbuild
export PACKAGE = blib
export VERSION = 1.0
SUBDIRS = etc bin lib usr

include distrib/macros.mk
-include distrib/${DISTRO}/macros.mk

distro:
	@if [ ! "${DISTRO}" ]; then echo Cannot detect the DISTRO >&2; exit 1; fi

install: distro
	$(foreach dir,${SUBDIRS},${MAKE} -C ${dir} install;)
	install -m 644 -D README ${DESTDIR}/${BLIB_BASE}/README
	
tarball: export DESTDIR=${HOME}/tmp/${PACKAGE}-${VERSION}
tarball: install
	$(foreach dir,. ${SUBDIRS},install -D ${dir}/Makefile ${DESTDIR}/${BLIB_BASE}/${dir}/Makefile;)
	install -m 644 -D distrib/${DISTRO}/${PACKAGE}.spec ${RPMBUILD}/SPECS/${PACKAGE}.spec
	install -m 644 -D distrib/macros.mk ${DESTDIR}/${BLIB_BASE}/distrib/macros.mk
	install -m 644 -D distrib/${DISTRO}/macros.mk ${DESTDIR}/${BLIB_BASE}/distrib/${DISTRO}/macros.mk
	install -m 644 -D README ${DESTDIR}/${BLIB_BASE}/README
	cd ${DESTDIR}; sed -i -e "s;@BLIB_BASE@;${BLIB_BASE};g" $$(find -type f)
	cd ${DESTDIR}/..; tar czf $(HOME)/rpmbuild/SOURCES/${PACKAGE}-${VERSION}.tgz ${PACKAGE}-${VERSION}
	
distrib: tarball
	cd ${RPMBUILD}/SPECS; rpmbuild -ba ${PACKAGE}.spec
	
PHONY: distrib install tarball all
