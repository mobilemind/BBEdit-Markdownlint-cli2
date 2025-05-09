# BBEdit Markdownlint-cli2

Lint Markdown within [BBEdit](http://www.barebones.com/products/bbedit/) using
[Markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2). Resulting
errors and warnings are opened in a results window within BBEdit, using the
BBEdit command line tool **bbresults**.

The `Markdownlint.bbpackage` packages a single script for passing the frontmost
document open in BBEdit to the markdownlint-cli2 command line interface.

This project was inspired by, and is structured similar to,
[BBEdit ESLint](https://github.com/ollicle/BBEdit-ESLint) by Oliver Boermans.

## Requirements

- [BBEdit](http://www.barebones.com/products/bbedit/) version 15.4 or greater
- BBEdit command line tools (“BBEdit > Install Command Line Tools”)
- [Markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) installed
  and configured as indicated in [markdownlint-cli2 — Configuration](https://github.com/DavidAnson/markdownlint-cli2#configuration)
  - No custom formatter configured— ie, no `markdownlint-cli2-formatter`,
    `markdownlint-cli2-formatter-template`, etc.
  - Either `"noProgress": false` (default), or `"noProgress": true` can be set
    in the active configuration file for markdownlint-cli2.
  
Initial development and testing was performed with:

- macOS Sequoia 15.4.1
- BBEdit 15.4.1
- markdownlint-cli2 v0.17.2 (markdownlint v0.37.4)

## Installation

1. Download and unzip the package:
   [Markdownlint-cli2.bbpackage_v0.9.5.zip](https://github.com/mobilemind/BBEdit-Markdownlint-cli2/raw/main/dist/Markdownlint-cli2.bbpackage_v0.9.5.zip)
2. Double–click the Markdownlint-cli2.bbpackage, BBEdit will prompt you to
   install (or update), and restart.

The package file will be copied to the Packages directory in BBEdit’s
Application Support directory. Delete it from here should you wish uninstall
later.

### Bring Your Own Markdownlint-cli2

As noted in the requirements, this package does not install Markdownlint-cli2
itself. The contained script assumes that **markdownlint-cli2** is
[installed](https://github.com/DavidAnson/markdownlint-cli2#install)
and [configured](https://github.com/DavidAnson/markdownlint-cli2#configuration).

This project includes a sample `.markdownlint-cli2.jsonc` configuration file
markdownlint-cli2 uses when checking this `README.md` file during the packaging
process.

The runtime script installed to BBEdit by the package depends on markdownlint-cli2.
If markdownlint-cli2 isn't installed, or is misconfigured, the Markdownlint-cli2
script will log errors to the BBEdit `Unix Script Output` file.

## Usage

Once installed the script **Markdownlint-cli2** will appear in the BBEdit
scripts menu. In addition **Markdownlint-cli2** will appear in the Scripts
palette where you can assign your own keyboard shortcut.

Open a Markdown file in BBEdit and trigger **Markdownlint-cli2**. A BBEdit
results window should open listing any Markdownlint-cli2 feedback. If there
are no warnings or errors to report nothing will happen.

- If markdownlint-cli2 finds no issues, a macOS notification is posted (assuming
  Do Not Disturb is off) and the default alert sound plays. The message title
  is "Markdownlint-cli2: {frontmost file name}" and the body is "No errors".
  This may be a clearer indication of scanning and success than nothing happening.
- If markdownlint-cli2 is missing or misconfigured, a macOS notification is
  posted (assuming Do Not Disturb is off), as well as logged to the
  `Unix Script Output` file, and the 'sosumi' system sound is played.
- If markdownlint-cli2 identifies issues with the file, no notification is posted.
  The BBEdit Results browser with the details should provide sufficient notification.

## Building the Package

In your Terminal clone the repository, change to the directory, and make the
package:

    git clone https://github.com/mobilemind/BBEdit-Markdownlint-cli2.git
    cd BBEdit-Markdownlint-cli2
    make

to also install the fresh build:

    make install

The make file will take advantage of [shellcheck](https://github.com/koalaman/shellcheck)
to check the `src/Scripts/Markdownlint-cli2.sh` shell script, if shellcheck is
installed. Likewise, it will use [cspell](https://github.com/streetsidesoftware/cspell)
to spell check the `README.md` file and the shell script. If those utilities
are not installed, the make file proceeds anyway.
