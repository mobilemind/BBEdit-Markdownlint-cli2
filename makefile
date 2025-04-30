#
# Makefile for Markdownlint-cli2.bbpackage
#

SRC_DIR = ./src
PKGNAME = Markdownlint-cli2.bbpackage
PKG = ./$(PKGNAME)
CONTENTS_DIR = $(PKG)/Contents
DIST_DIR = ./dist
INFO_PATH = $(PWD)/src/Info
VERSION = $(shell defaults read $(INFO_PATH) CFBundleShortVersionString)
ZIP = ./$(PKGNAME)_v$(VERSION).zip

.DEFAULT: all

.PHONY: all clean install

all: clean build

clean:
	-rm -rf $(PKG)
	-rm -rf $(DIST_DIR)
	-find . -name '.DS_Store' -exec rm -rf {} \+

install: all
	open $(PKG)/.

build: $(PKG) $(ZIP)

dist: all
	# update the link to the dist file
	perl -i -pe "s/$(PKGNAME)_v.*?\.zip/$(PKGNAME)_v$(VERSION).zip/g" README.md
	# spellcheck things if cspell is installed
	if hash cspell > /dev/null 2>&1 && [ -s "$HOME/.cspell/.cspell.json" ] ; then \
		cspell lint -c "$HOME/.cspell/.cspell.json" README.md LICENSE src/Scripts/*.sh ; \
	fi
	@echo
	@echo "Remember to commit & push changes, plus 'git tag v$(VERSION) && git push --tags' AND make a release."

$(PKG):
	# shellcheck scripts if it's available
	if hash shellcheck > /dev/null 2>&1 ; then shellcheck -s sh src/Scripts/*.sh ; fi
	# format check the README.md (verifies that 'npx' & 'markdownlint-cli2' are installed)
	npx markdownlint-cli2 README.md
	mkdir -p $(CONTENTS_DIR)
	cp README.md $(PKG)/.
	cp LICEN* $(PKG)/.
	cp -R $(SRC_DIR)/* $(CONTENTS_DIR)/.

$(ZIP):
	mkdir -p $(DIST_DIR)
	zip -r $(DIST_DIR)/$(ZIP) $(PKG)
