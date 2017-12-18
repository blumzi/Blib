enter-dim-mode := $(shell tput dim)
exit-dim-mode  := $(shell tput sgr0)

define announce
	$(eval tag     := $$(shell printf "%-20s" "${1}"))
	$(eval summary := $2)

	@echo "${enter-dim-mode}${tag}${exit-dim-mode}${summary}"
endef

define run
	$(eval tag     := $1)
	$(eval summary := $2)
	$(eval command := $3)

	$(call announce,${tag},${summary})
	@$(if ${command},${command} 2>&1 | sed 's;^;  ;')
endef
