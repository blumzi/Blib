DISTRO=$(shell \
        if [ -r /etc/centos-release ]; then \
            echo centos; \
        elif [ -r /etc/os-release ]; then \
            . /etc/os-release; \
            if [  "$${ID}" ]; then \
                echo "$${ID}"; \
            elif [ "$${ID_LIKE}" ]; then \
                echo "$${ID_LIKE}"; \
            fi; \
        fi )

define packaging-method
$(if $(findstring ${DISTRO},debian ubuntu),deb,rpm)
endef

TOP=$(shell git rev-parse --show-toplevel)
PACKAGE_NAME = blib
