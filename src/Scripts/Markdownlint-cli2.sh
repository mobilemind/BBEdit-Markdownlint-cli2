#!/bin/sh

SHORTNAME="$(basename "$BB_DOC_PATH")"
SCRIPT="$(basename "$0" '.sh')"
SCRIPTDIR="$(pwd)"
ASNOTIFY="${SCRIPTDIR%/*}/Resources/as-notify.scpt"
VERSION="PLIST_VERSION"

NOTIFY() { # $1=Title, $2=Message, $3=Sound
	(nohup osascript "$ASNOTIFY" "$1" "$2" "$3" >/dev/null 2>&1 &)
}

# check for npx
if ! hash npx > /dev/null 2>&1 ; then
	NOTIFY "$SCRIPT: ERROR" "npx not found. Try installing npm. Then restart BBedit." 'sosumi'
	echo "ERROR: npx not found. Try installing npm. Then restart BBedit. (v$VERSION)"
	exit 1
fi

# check for markdownlint-cli2
if ! hash markdownlint-cli2 > /dev/null 2>&1 ; then
	NOTIFY "$SCRIPT: ERROR" "markdownlint-cli2 not installed. Try installing it with 'npm install -g markdownlint-cli2'. Then restart BBedit." 'sosumi'
	echo "ERROR: markdownlint-cli2 not installed. Try installing it with 'npm install -g markdownlint-cli2' then restart BBEdit. (v$VERSION)"
	exit 1
fi

# confirm there is a non-empty file to check
if [ ! -s "${BB_DOC_PATH}" ] ; then
	NOTIFY "$SCRIPT: ERROR" "BB_DOC_PATH not found, or empty: '$BB_DOC_PATH'" 'sosumi'
	echo "ERROR: File '${BB_DOC_PATH}' from BBEdit was not found or empty. (v$VERSION)"
	exit 1
fi

# if BB_DOC_PATH is within $BB_DOC_WORKSPACE_ROOT, then make path more readable
if [ -n "$BB_DOC_WORKSPACE_ROOT" ] && [ "${BB_DOC_PATH#*"$BB_DOC_WORKSPACE_ROOT"}" != "$BB_DOC_PATH" ]; then
	cd "$BB_DOC_WORKSPACE_ROOT" > /dev/null 2>&1 || true
fi


if npx markdownlint-cli2 "${BB_DOC_PATH}" > /dev/null 2>&1 ; then
	# return code 0 = no errors
	NOTIFY "$SCRIPT: $SHORTNAME" 'No errors.' 'default'
	exit 0
elif [ "$?" -eq 2 ] ; then
	NOTIFY "$SCRIPT: ERROR" "No results from 'npx markdownlint-cli2 \"$BB_DOC_PATH\", check configuration." 'sosumi'
	echo "SCRIPT: ERROR: No results from 'npx markdownlint-cli2 \"${BB_DOC_PATH}\". Check configuration. (v$VERSION)"
	npx markdownlint-cli2 "${BB_DOC_PATH}"
	exit 1
fi

RESULTS="$(npx markdownlint-cli2 "${BB_DOC_PATH}" 2>&1)"

# check results
if [ -z "$RESULTS" ] ; then
	# no results is an error, there should at least be summary info
	NOTIFY "$SCRIPT: ERROR" "No results from 'npx markdownlint-cli2 \"$BB_DOC_PATH\", check configuration." 'sosumi'
	echo "SCRIPT: ERROR: No results from 'npx markdownlint-cli2 \"${BB_DOC_PATH}\". Check configuration. (v$VERSION)"
	exit 1
fi

# when the config for markdownlint-cli2 has "noProgress": true"
# AND there's no errors, results looks like: 'markdownlint-cli2 v0.17.2 (markdownlint v0.37.4)'
# OR if "noProgress": true" and there's no errors, a summary shows 0 errors
# shellcheck disable=SC2143
if [ -z "$(echo "$RESULTS" | grep -Ev 'markdownlint-cli2 v[0-9]+\.[0-9]+\.[0-9]+ \(markdownlint v[0-9]+\.[0-9]+\.[0-9]+\)')" ] || echo "$RESULTS" | grep -Fq 'Summary: 0 error(s)' > /dev/null 2>&1 ; then
	# no errors, indicate success with terminal notifier and default sound before exiting
	NOTIFY "$SCRIPT: $SHORTNAME" 'No errors.' 'default'
	exit 0
fi

# trim summary or version info from the top to pass bbresults a clean list of issues
RESULTS="$(echo "$RESULTS" | sed '/^markdownlint-cli2 v/d; /^Linting: /,/^Summary: /d')"

# set BBEdit results RegEx pattern for markdownlint-cli2 default output
PATTERN='(?P<file>.+?):(?P<line>\d+)?(:(?P<col>\d+))? (?P<type>\S+) (?P<msg>.*)$'

# to debug, uncomment the line below and check the BBEdit "Unix Script Output.log" file.
# echo "$RESULTS"

# send results back to BBEdit (no need to notify, since Results browser appears)
echo "$RESULTS" | bbresults --pattern "$PATTERN"
