VERSION := $(shell ruby -r ./lib/hiera/backend/eyaml/encryptors/age/version \
  -e 'puts Hiera::Backend::Eyaml::Encryptors::AgeVersion::VERSION')
export DEBEMAIL:=network@ias.edu


.PHONY: gem
gem: hiera-eyaml-age-$(VERSION).gem

.PHONY: deb
deb: hiera-eyaml-age-$(VERSION).gem
	gem2deb --package hiera-eyaml-age hiera-eyaml-age-$(VERSION).gem

targz:
	git archive --output hiera-eyaml-age_$(VERSION).tar.gz --prefix hiera-eyaml-age main

.PHONY: packages
packages: deb gem targz

hiera-eyaml-age-$(VERSION).gem:
	gem build hiera-eyaml-age.gemspec

.PHONY: clean
clean:
	rm -rf \
		gem2deb* \
		hiera-eyaml-age-* \
		ruby* \
		hiera-eyaml-age-* \
		hiera-eyaml-age_*
