#!/bin/sh

SHORTNAME="$(basename "$BB_DOC_PATH")"
SCRIPT="$(basename "$0" '.sh')"

# check for npx
if ! hash npx > /dev/null 2>&1 ; then
	osascript -e "display notification \"npx not found. Try installing npm. Then restart BBedit.\" with title \"$SCRIPT: ERROR\" subtitle \"\" sound name \"sosumi\""
	echo "ERROR: markdownlint-cli2 not installed. Try installing it with 'npm install -g npx' and/or adding it to your PATH variable. Then restart BBedit."
	exit 1
fi

# check for markdownlint-cli2
if ! hash markdownlint-cli2 > /dev/null 2>&1 ; then
	osascript -e "display notification \"markdownlint-cli2 not installed. Try installing it with 'npm install -g markdownlint-cli2'. Then restart BBedit.\" with title \"$SCRIPT: ERROR\" subtitle \"\" sound name \"sosumi\""
	echo "ERROR: markdownlint-cli2 not installed. Try installing it with 'npm install -g markdownlint-cli2' then restart Terminal."
	exit 1
fi

# confirm there is a non-empty file to check
if [ ! -s "${BB_DOC_PATH}" ] ; then
	osascript -e "display notification \"BB_DOC_PATH not found, or empty:\" & return & \"${BB_DOC_PATH}\" with title \"$SCRIPT: ERROR\" subtitle \"\" sound name \"sosumi\""
	echo "ERROR: File '${BB_DOC_PATH}' from BBEdit was not found or empty."
	exit 1
fi

# if BB_DOC_PATH is within $BB_DOC_WORKSPACE_ROOT, then make path more readable
if [ -n "$BB_DOC_WORKSPACE_ROOT" ] && [ "${BB_DOC_PATH#*"$BB_DOC_WORKSPACE_ROOT"}" != "$BB_DOC_PATH" ]; then
	cd "$BB_DOC_WORKSPACE_ROOT" > /dev/null 2>&1 || true
fi

RESULTS="$(npx markdownlint-cli2 "${BB_DOC_PATH}" 2>&1 || echo '')"

# check results
if [ -z "$RESULTS" ] ; then
	# no results is an error, there should at least be summary info
	osascript -e "display notification \"No results from 'npx markdownlint-cli2 \" & quote & \"${BB_DOC_PATH}\" & quote & \"'. Check configuration.\" with title \"$SCRIPT: ERROR\" subtitle \"\" sound name \"sosumi\""
	echo "SCRIPT: ERROR: No results from 'npx markdownlint-cli2 \"${BB_DOC_PATH}\". Check configuration."
	exit 1
fi

# when the config for markdownlint-cli2 has "noProgress": true"
# AND there's no errors, results looks like: 'markdownlint-cli2 v0.17.2 (markdownlint v0.37.4)'
# OR if "noProgress": true" and there's no errors, a summary shows 0 errors
# shellcheck disable=SC2143
if [ -z "$(echo "$RESULTS" | grep -Ev 'markdownlint-cli2 v[0-9]+\.[0-9]+\.[0-9]+ \(markdownlint v[0-9]+\.[0-9]+\.[0-9]+\)')" ] || echo "$RESULTS" | grep -Fq 'Summary: 0 error(s)' > /dev/null 2>&1 ; then
	# no errors, indicate success with terminal notifier and default sound before exiting
	osascript -e "display notification \"No errors.\" with title \"$SCRIPT: $SHORTNAME\" subtitle \"\" sound name \"default\""
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
