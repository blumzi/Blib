-include deb.mk
-include run.mk
-include ../macros.mk

version  := 1.0
arch     := all
package  := blib_${version}_${arch}.deb
controls := control postinst prerm conffiles

STAGING_AREA=$(TOP)/staging-area/$(DISTRO)/$(PACKAGE_NAME)

pack:
	mkdir -p $(STAGING_AREA)/DEBIAN
	$(foreach d,bin lib etc usr,$(MAKE) -C $(TOP)/$(d) STAGING_AREA=$(STAGING_AREA) install; )
	install -m 644 -D control $(STAGING_AREA)/DEBIAN/control
	install -m 755 -D postinst $(STAGING_AREA)/DEBIAN/postinst
	install -m 755 -D prerm $(STAGING_AREA)/DEBIAN/prerm
	cd $(STAGING_AREA)/..; fakeroot dpkg-deb --build $(PACKAGE_NAME) $(package) ; lintian --no-tag-display-limit $(package)
	@echo "\n $(DISTRO) package ready in $(dir $(STAGING_AREA))$(package)\n"

clean:
	rm -rf $(STAGING_AREA)

.PHONY: pack clean
