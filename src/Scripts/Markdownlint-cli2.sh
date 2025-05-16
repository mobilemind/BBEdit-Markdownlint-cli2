#!/bin/sh

# shellcheck disable=SC2181

SHORTNAME="$(basename "$BB_DOC_PATH")"
SCRIPT="$(basename "$0" '.sh')"
SCRIPTDIR="$(pwd)"
ASNOTIFY="${SCRIPTDIR%/*}/Resources/as-notify.scpt"
VERSION="PLIST_VERSION"

NOTIFY() { # $1=Title, $2=Message, $3=Sound
	(nohup osascript "$ASNOTIFY" "$1" "$2" "$3" >/dev/null 2>&1 &)
}

# check for markdownlint-cli2
if ! hash markdownlint-cli2 > /dev/null 2>&1 ; then
	NOTIFY "$SCRIPT: ERROR" "markdownlint-cli2 not found. Try installing it with 'npm install -g markdownlint-cli2'. Then restart BBEdit." 'sosumi'
	echo "ERROR: markdownlint-cli2 not found. Try installing it with 'npm install -g markdownlint-cli2' then restart BBEdit. (v$VERSION)"
	exit 1
fi

# confirm there is a non-empty file to check
if [ ! -s "${BB_DOC_PATH}" ] ; then
	NOTIFY "$SCRIPT: ERROR" "BB_DOC_PATH not found, or empty: '$BB_DOC_PATH'" 'sosumi'
	echo "ERROR: File '${BB_DOC_PATH}' from BBEdit was not found or empty. (v$VERSION)"
	exit 1
fi

# if BB_DOC_PATH is within $BB_DOC_WORKSPACE_ROOT, then make path more readable
if [ -n "$BB_DOC_WORKSPACE_ROOT" ] && [ "${BB_DOC_PATH#*"$BB_DOC_WORKSPACE_ROOT"}" != "$BB_DOC_PATH" ] ; then
	cd "$BB_DOC_WORKSPACE_ROOT" > /dev/null 2>&1 || true
fi

# handle temporary files & their clean-up
umask 037
MDL_ERRORS="$(mktemp -t bbedit_markdownlint)" # will hold DocC errors for processing
if [ "$?" -ne 0 ] ; then
	NOTIFY "$SCRIPT: ERROR" "Can't create temp file" 'sosumi'
	echo "ERROR: Can't create temp file. $SCRIPT (v$VERSION)"
	exit 1
fi
# trap for cleanup (and remove it on the way out to not double-trigger)
trap 'rm -rf "$MDL_ERRORS" ; trap - EXIT; exit' EXIT INT HUP

# markdownlint-cli2 returns: 0=no errors, 1=markdown warnings or errors identified, 2=configuration error or unable to parse
if markdownlint-cli2 "${BB_DOC_PATH}" > "$MDL_ERRORS" 2>&1 ; then
	# return code 0 = no errors
	NOTIFY "$SCRIPT: $SHORTNAME" 'No errors.' 'default'
	exit 0
elif [ "$?" -eq 2 ] || [ ! -s "$MDL_ERRORS" ] ; then
	# config/processing error code from markdownlint-cli2 OR results file is empty
	NOTIFY "$SCRIPT: ERROR" "Configuration or other error- no results from 'npx markdownlint-cli2 \"$BB_DOC_PATH\", check configuration." 'sosumi'
	echo "SCRIPT: ERROR: Configuration or other error- no results from 'npx markdownlint-cli2 \"${BB_DOC_PATH}\". Check configuration. (v$VERSION)"
	cat "$MDL_ERRORS"
	exit 1
fi

# set BBEdit results RegEx pattern for markdownlint-cli2 default output
PATTERN='(?P<file>.+?):(?P<line>\d+)?(:(?P<col>\d+))? (?P<type>\S+) (?P<msg>.*)$'

# trim summary or version info from the top of MDL_ERRORS to make a clean list of issues
# and pipe results bbresults for BBEdit to show (no need to notify, since BBEdit Results Browser appears)
sed '/^markdownlint-cli2 v/d; /^Linting: /,/^Summary: /d' "$MDL_ERRORS" | bbresults --pattern "$PATTERN"
