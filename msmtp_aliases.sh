#!/bin/sh
# Copyright (c) 2011 Alejandro Mery <amery@geeks.cl>
# 
# Permission is hereby granted, free of charge, to any
# person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the
# Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the
# Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of
# the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Supported ENV vars:
# * DOMAIN: domain to append to usersnames without an alias (default: example.org)
# * TMPDIR: directory to temporarily store the messages
# * MSMTP_ALIASES_NEXT: preferred next `msmtp` wrapper
# * MSMTP: generic next `msmtp` wrapper

DOMAIN=${DOMAIN:-example.org}
TMPFILE="${TMPDIR:-/tmp}/msmtp_aliases.$$"
LOGFILE="$HOME/msmtp_aliases.log"

NEXT="${MSMTP_ALIASES_NEXT:-$MSMTP}"
[ -n "$NEXT" ] || NEXT=$(which msmtp || echo "/usr/local/bin/msmtp")

log() {
	local P="[$(date +%Y-%m-%d-%H.%M.%S)] [$$]"

	echo "$P:$*" >> "$LOGFILE"
}

log "  $0 $*"

cat > $TMPFILE # email content
ARGS= mangled= read_recipients=

while [ $# -gt 0 ]; do
	case "$1" in
	-f|-O|-ox|-X|-C|-a|-N|-R|-L)
		ARGS="$ARGS $1 $2"; shift ;;
	-t)	ARGS="$ARGS $1" read_recipients=yes ;;
	--)	ARGS="$ARGS --"; break ;;
	-*)	ARGS="$ARGS $1" ;;
	*)	break;
	esac
	shift
done

alias_of() {
	local x="$1" alias=
	alias=$(awk -- "/^$x:/ { print \$2;}" "/etc/aliases" 2> /dev/null)
	echo "${alias:-$x@$DOMAIN}"
}

for x; do
	case "$x" in
	*@*) ARGS="$ARGS $x" ;;
	*)
		ARGS="$ARGS $(alias_of $x)"
		mangled=true
		;;
	esac
done

if [ -n "$read_recipients" ]; then
	for x in $(sed -n -e 's,^To: .*<\([^@]\+\)>$,\1,p' "$TMPFILE"); do
		y="$(alias_of $x)"
		log "  To: <$x> -> <$y>"
		sed -i "s,^To: \(.*\)<$x>$,To: \1<$y>," "$TMPFILE"
	done
fi

eval "set -- $ARGS"
[ -z "$mangled" ] || log "+ $0 $@"

"$NEXT" "$@" < "$TMPFILE"
errno=$?
rm -f "$TMPFILE"
exit $errno
