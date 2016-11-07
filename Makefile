all:

RPMBUILD = $(HOME)/rpmbuild
PACKAGE = blib
VERSION = 1.0
DISTRO=$(shell \
	if [ -r /etc/centos-release ]; then \
		echo centos; \
	elif [ -r /etc/redhat-release ]; then \
		echo redhat;\
	fi)
DESTDIR = $(HOME)/tmp/${PACKAGE}-${VERSION}
SUBDIRS = etc bin lib usr

install:
	$(MAKE) -C etc DESTDIR=$(DESTDIR) install
	$(MAKE) -C bin DESTDIR=$(DESTDIR) install
	$(MAKE) -C lib DESTDIR=$(DESTDIR) install
	$(MAKE) -C usr DESTDIR=$(DESTDIR) install
	
tarball: TMP = ${HOME}/tmp/${PACKAGE}-${VERSION}
tarball: 
	$(foreach dir,${SUBDIRS},${MAKE} -C ${dir} DESTDIR=${TMP} install;)
	$(foreach dir,${SUBDIRS},install -D ${dir}/Makefile ${TMP}/${dir}/Makefile;)
	install -m 644 -D Makefile ${DESTDIR}/Makefile
	install -m 644 -D distrib/${DISTRO}/${PACKAGE}.spec ${RPMBUILD}/SPECS/${PACKAGE}.spec
	cd ${TMP}/..; tar czf $(HOME)/rpmbuild/SOURCES/${PACKAGE}-${VERSION}.tgz ${PACKAGE}-${VERSION}
	
distrib: tarball
	cd ${RPMBUILD}/SPECS; rpmbuild -ba ${PACKAGE}.spec
	
.PHONY: distrib install
