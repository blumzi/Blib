MODULES = calc.sh cleanup.sh command.sh conf.sh const.sh dmi.sh doc.sh error.sh flock.sh http.sh ip.sh \
		list.sh log.sh misc.sh module.sh mutex.sh netif.sh pci.sh str.sh tap.sh time.sh tmp.sh \
		trace.sh user.sh xmlrpc.sh xml.sh doc/doctext.sh doc/docmd.sh aws/ec2.sh slurm.sh

include ../distrib/${DISTRO}/macros.mk

install:
ifeq ($(STAGING_AREA),)
	$(error Missing STAGING_AREA))
endif
	$(foreach module,$(MODULES),install -m 644 -D ${module} $(STAGING_AREA)/usr/share/$(PACKAGE_NAME)/lib/${module};)

.PHONY: install
