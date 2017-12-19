RPMBUILD = $(HOME)/rpmbuild
export PACKAGE = blib
export VERSION = 1.0
SUBDIRS = etc bin lib usr
TARBALL = $(DESTDIR)/${PACKAGE}-${VERSION}.tgz
export STAGING_AREA = ${HOME}/tmp/${PACKAGE}-${VERSION}

include distrib/macros.mk
-include distrib/${DISTRO}/macros.mk

ifneq ($(findstring $(DISTRO),ubuntu debian),)
	distrib = distrib/ubuntu
else ifneq ($(findstring $(DISTRO),redhat centos),)
	distrib = distrib/redhat
else
	$(error *** Unsupported distribution "${DISTRO}" ***)
endif

pack clean:
	$(MAKE) -C $(distrib) $(@)

PHONY: pack clean
