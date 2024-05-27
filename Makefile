# Binwalk analysis plugin for REHex
# Copyright (C) 2024 Daniel Collins <solemnwarning@solemnwarning.net>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 as published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Define this when releasing
# VERSION := x.y.z

prefix      ?= /usr/local
exec_prefix ?= $(prefix)
bindir      ?= $(exec_prefix)/bin
datarootdir ?= $(prefix)/share
libdir      ?= $(exec_prefix)/lib

PLUGINS_INST_DIR ?= $(DESTDIR)$(libdir)/rehex

DIST_FILES := \
	binwalk.lua \
	LICENSE \
	Makefile

.PHONY: all
all:

.PHONY: install
install:
	mkdir -p "$(PLUGINS_INST_DIR)"
	install -m 0644 "binwalk.lua" "$(PLUGINS_INST_DIR)/binwalk.lua"

.PHONY: dist
dist:
	test -n "$(VERSION)" # VERSION must be defined
	rm -rf "rehex-plugin-binwalk-$(VERSION)/" "rehex-plugin-binwalk-$(VERSION).tar.gz"
	mkdir "rehex-plugin-binwalk-$(VERSION)/"
	cp $(DIST_FILES) "rehex-plugin-binwalk-$(VERSION)/"
	tar -czf "rehex-plugin-binwalk-$(VERSION).tar.gz" "rehex-plugin-binwalk-$(VERSION)/"

.PHONY: srpm
srpm: dist
	mkdir -p rpmbuild/SOURCES rpmbuild/SPECS
	cp "rehex-plugin-binwalk-$(VERSION).tar.gz" rpmbuild/SOURCES/
	sed -e 's/PUT_VERSION_HERE/$(VERSION)/g' < spec/rehex-plugin-binwalk.spec > rpmbuild/SPECS/rehex-plugin-binwalk.spec
	rpmbuild -bs rpmbuild/SPECS/rehex-plugin-binwalk.spec --define "_topdir $$(pwd)/rpmbuild/"
