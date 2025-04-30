#!/bin/sh

SHORTNAME="$(basename "$BB_DOC_PATH")"
SCRIPT="$(basename "$0" '.sh')"

NOTIFY() { # $1=TITLE , $2=MESSAGE, $3=SOUND
	hash terminal-notifier >/dev/null 2>&1 && \
			(nohup terminal-notifier -title "$1" -message "$2" -sound "$3" >/dev/null 2>&1 &)
}

# check for npx
if ! hash npx > /dev/null 2>&1 ; then
	NOTIFY "SCRIPT: ERROR" "npx not installed. Try installing it with 'npm install -g npx' and/or adding it to your PATH variable. Then restart BBedit." 'sosumi'
	echo "ERROR: markdownlint-cli2 not installed. Try installing it with 'npm install -g npx' and/or adding it to your PATH variable. Then restart BBedit."
	exit 1
fi

# check for markdownlint-cli2
if ! hash markdownlint-cli2 > /dev/null 2>&1 ; then
	NOTIFY "SCRIPT: ERROR" "markdownlint-cli2 not installed. Try installing it with 'npm install -g markdownlint-cli2' then restart BBedit." 'sosumi'
	echo "ERROR: markdownlint-cli2 not installed. Try installing it with 'npm install -g markdownlint-cli2' then restart Terminal."
	exit 1
fi

# confirm there is a non-empty file to check
if [ ! -s "${BB_DOC_PATH}" ] ; then
	NOTIFY "SCRIPT: ERROR" "\"${BB_DOC_PATH}\" not found or empty." 'sosumi'
	echo "ERROR: File '${BB_DOC_PATH}' from BBEdit was not found or empty."
	exit 1
fi

RESULTS="$(npx markdownlint-cli2 "${BB_DOC_PATH}" 2>&1 || echo '')"

# check results
if [ -z "$RESULTS" ] ; then
	# no results is an error, there should at least be summary info
	NOTIFY "SCRIPT: ERROR" "No results from 'npx markdownlint-cli2 \"${BB_DOC_PATH}\". Check configuration." 'sosumi'
	echo "SCRIPT: ERROR: No results from 'npx markdownlint-cli2 \"${BB_DOC_PATH}\". Check configuration."
	exit 1
fi

# when the config for markdownlint-cli2 has "noProgress": true"
# AND there's no errors, results looks like: 'markdownlint-cli2 v0.17.2 (markdownlint v0.37.4)'
# OR if "noProgress": true" and there's no errors, a summary shows 0 errors
# shellcheck disable=SC2143
if [ -z "$(echo "$RESULTS" | grep -Ev 'markdownlint-cli2 v[0-9]+\.[0-9]+\.[0-9]+ \(markdownlint v[0-9]+\.[0-9]+\.[0-9]+\)')" ] || echo "$RESULTS" | grep -Fq 'Summary: 0 error(s)' > /dev/null 2>&1 ; then
	# no errors, indicate success with terminal notifier and default sound before exiting
	NOTIFY "$SCRIPT $SHORTNAME" 'No errors.' 'default'
	exit 0
fi

# trim summary or version info from the top to pass bbresults a clean list of issues
RESULTS="$(echo "$RESULTS" | sed '/^markdownlint-cli2 v/d; /^Linting: /,/^Summary: /d')"
echo "RESULTS: $RESULTS"

# set BBEdit results RegEx pattern for markdownlint-cli2 default output
PATTERN='(?P<file>.+?):(?P<line>\d+)?(:(?P<col>\d+))? (?P<type>\S+) (?P<msg>.*)$'

# send results back to BBEdit (no need to notify, since Results browser appears)
echo "$RESULTS" | bbresults --pattern "$PATTERN"
