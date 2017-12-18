SPECS = $(HOME)/rpmbuild/SPECS

install:
	$(CP) blib.spec $(SPECS)
	
rpm: blib.spec
	cd $(SPECS); rpmbuild blib.spec
