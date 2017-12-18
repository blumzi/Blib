define make-meta-deb
	$(eval tmp= $(shell mktemp -d /tmp/make-meta-deb.XXXXXXXX))
	$(eval controls   = $1)
	$(eval package    = $2)
	$(eval controls.d = ${tmp}/controls.d)
	$(eval DEBIAN.d   = ${tmp}/debian/DEBIAN)

	mkdir -p ${controls.d} ${deb.d} ${DEBIAN.d}
	cp ${controls} ${DEBIAN.d}
	chmod 755 ${DEBIAN.d}/p* 2>&-; exit 0
	chmod 644 ${DEBIAN.d}/control
	here=$$(pwd); cd ${tmp}; dpkg-deb --build debian >/dev/null 2>&1 && (mv debian.deb $${here}/${package}; rm -rf ${tmp}) || exit $?
	rm -rf ${tmp}
endef

define make-deb-from-tgz
	$(eval tmp= $(shell mktemp -d /tmp/make-meta-deb.XXXXXXXX))
	$(eval controls   = $1)
	$(eval package    = $2)
	$(eval tgz  	  = $3)
	$(eval controls.d = ${tmp}/controls.d)
	$(eval DEBIAN.d   = ${tmp}/debian/DEBIAN)

	mkdir -p ${controls.d} ${deb.d} ${DEBIAN.d}
	cp ${controls} ${DEBIAN.d}
	chmod 755 ${DEBIAN.d}/p* 2>&-; exit 0
	chmod 644 ${DEBIAN.d}/control
	cd ${DEBIAN.d} ; tar xzf ${tgz}
	here=$$(pwd); cd ${tmp}; dpkg-deb --build debian >/dev/null 2>&1 && (mv debian.deb $${here}/${package}; rm -rf ${tmp}) || exit $?
	rm -rf ${tmp}
endef
