export PACKAGE = blib
export VERSION = 1.0
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

default: help

help:
	@echo ''
	@echo "Blib goals:"
	@echo "	pack:  produces an installable ${PACKAGE} (version: ${VERSION}) package for ${DISTRO}"
	@echo "	clean: removes intermediate files"
	@echo ''

pack clean:
	$(MAKE) -C $(distrib) $(@)

PHONY: pack clean
