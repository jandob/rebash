ifndef PREFIX
	override PREFIX=/usr/local
endif

VERSION=0.0.8

.PHONY: test install package

test:
	bash rebash.sh --side-by-side --no-check-undocumented -v

install:
	install -b rebash.sh $(PREFIX)/bin/rebash
	mkdir -p $(PREFIX)/lib/rebash
	sudo cp -f src/* $(PREFIX)/lib/rebash/
	bash after-install.sh

package:
	mkdir -p ./dist
	# fpm -t pacman -p dist/rebash-$(VERSION)-any.pkg bsdtar required?
	fpm -t deb -p dist/rebash-$(VERSION)-any.deb
	fpm -t rpm -p dist/rebash-$(VERSION)-any.rpm
	fpm -t apk --depends coreutils -p dist/rebash-$(VERSION)-any.apk

docker:
	make package
	docker build -t jandob/rebash:0.0.8 .
	docker push jandob/rebash:0.0.8 && \
		docker tag jandob/rebash:0.0.8 jandob/rebash:latest && \
		docker push jandob/rebash:latest
