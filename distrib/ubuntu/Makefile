-include deb.mk
-include run.mk
-include ../macros.mk

version := 1.0
arch    := all
package := blib_${version}_${arch}.deb

controls := control postinst prerm

${package}: ${controls}
	@$(call run,deb,$@,$$(call make-deb-from-tgz,${controls},${@},$(TARBALL)))

clean:
	@$(call run,deb-clean,${package},rm -f ${package})

install: ${package}
	@$(call run,deb-install,${package} -> ${INSTALL-DIR},install -D -m 644 ${package} ${INSTALL-DIR}/${package})

distrib: STAGING_AREA=$(TOP)/staging-area/$(DISTRO)/$(PACKAGE_NAME)
distrib:
	mkdir -p $(STAGING_AREA)/DEBIAN
	$(foreach dir,bin lib usr,$(MAKE) -C $(TOP)/$(dir) STAGING_AREA=$(STAGING_AREA) install; )
	install -m 644 -D control $(STAGING_AREA)/DEBIAN/control
	install -m 755 postinst $(STAGING_AREA)/DEBIAN/postinst
	install -m 755 prerm $(STAGING_AREA)/DEBIAN/prerm
	cd $(STAGING_AREA)/..; fakeroot dpkg-deb --build $(PACKAGE_NAME) ; lintian --no-tag-display-limit $(PACKAGE_NAME).deb

.PHONY: clean install distrib
