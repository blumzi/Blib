RPMBUILD = $(HOME)/rpmbuild
export PACKAGE = blib
export VERSION = 1.0
SUBDIRS = etc bin lib usr
TARBALL = $(DESTDIR)/${PACKAGE}-${VERSION}.tgz
export STAGING_AREA = ${HOME}/tmp/${PACKAGE}-${VERSION}

include distrib/macros.mk
-include distrib/${DISTRO}/macros.mk

supported-distros := centos debian ubuntu redhat

ifeq ($(findstring ${DISTRO},${supported-distros}),)
$(error *** Unsupported distribution "${DISTRO}")
endif

packaging = $(call packaging-method)

DESTDIR = $(if $(findstring ${packaging},deb),$(shell pwd)/distrib/debian/opt,$(HOME)/rpmbuild/SOURCES)

distro:
	@if [ ! "${DISTRO}" ]; then echo Cannot detect the DISTRO >&2; exit 1; fi

install: distro
	$(foreach dir,${SUBDIRS},${MAKE} -C ${dir} DESTDIR=${TMP} install;)
	install -m 644 -D README ${TMP}/${BLIB_BASE}/README
	
tarball: export TMP=${HOME}/tmp/${PACKAGE}-${VERSION}
tarball: install
ifeq (${packaging},rpm)
	install -m 644 -D distrib/${DISTRO}/${PACKAGE}.spec 	${RPMBUILD}/SPECS/${PACKAGE}.spec
	sed -i -e "s;@BLIB_BASE@;${BLIB_BASE};g"				${RPMBUILD}/SPECS/${PACKAGE}.spec
endif
	install -m 644 -D distrib/macros.mk						${TMP}/${BLIB_BASE}/distrib/macros.mk
	install -m 644 -D distrib/${DISTRO}/macros.mk			${TMP}/${BLIB_BASE}/distrib/${DISTRO}/macros.mk
	cd ${TMP}; sed -i -e "s;@BLIB_BASE@;${BLIB_BASE};g" 	$$(find -type f)
ifeq (${packaging},deb)
	cd ${TMP}; tar czf ../data.tgz ./opt
else ifeq (${packaging},rpm)
	cd ${TMP}/..; tar czf ${PACKAGE}-${VERSION}.tgz ${PACKAGE}-${VERSION}
endif
	
distrib: tarball
ifneq ($(findstring $(DISTRO),ubuntu debian),)
	$(MAKE) -C distrib/ubuntu $(@)
else ifneq ($(findstring $(DISTRO),ubuntu debian),)
	$(MAKE) -C redhatmdistrib/redhat $(@)
else
	$(error *** Unsupported distribution "${DISTRO}")
endif

PHONY: distrib install tarball all
