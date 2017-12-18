SPECS = $(HOME)/rpmbuild/SPECS

install:
	install blib.spec $(SPECS)
	
rpm: install
	cd $(SPECS); rpmbuild blib.spec
	
.PHONY: install rpm
