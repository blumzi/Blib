MODULES = calc.sh command.sh conf.sh const.sh dmi.sh doc.sh error.sh flock.sh http.sh ip.sh \
		list.sh log.sh misc.sh module.sh mutex.sh netif.sh pci.sh str.sh tap.sh time.sh tmp.sh \
		trace.sh user.sh xmlrpc.sh xml.sh doc/doctext.sh

install:
	$(foreach module,$(MODULES),install -m 644 -D ${module} ${DESTDIR}/lib/${module};)

.PHONY: install
