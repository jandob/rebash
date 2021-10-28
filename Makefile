ifndef PREFIX
	override PREFIX=/usr/local
endif

VERSION=0.0.8

.PHONY: package

package:
	mkdir -p ./dist
	# fpm -t pacman -p dist/rebash-$(VERSION)-any.pkg bsdtar required?
	fpm -t deb -p dist/rebash-$(VERSION)-any.deb
	fpm -t rpm -p dist/rebash-$(VERSION)-any.rpm
	fpm -t apk -p dist/rebash-$(VERSION)-any.apk
