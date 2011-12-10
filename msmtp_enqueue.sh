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

umask 077

QUEUE="$HOME/.msmtp-queue"
TSTAMP=$(date +%Y-%m-%d-%H.%M.%S)

BASE="$QUEUE/$TSTAMP"
LOCK="$BASE.lock"

die() {
	if [ $# -gt 0 ]; then
		echo "$@" >&2
	fi
	exit 1
}

die2() {
	rm -f "$LOCK" "$MSG" "$ARGS" "$MSG.pid"
	die "$@"
}

mkdir -p "$QUEUE" || die "$QUEUE: can't create dir"

# busy wait for a lock
while ! ln -s "$BASE" "$LOCK" 2> /dev/null; do
	:
done

# find unique name
i=0 B="$BASE"
ARGS="$B.args"
while [ -f "$ARGS" ]; do
	i=$(expr $i + 1)
	B="$BASE-$i"
	ARGS="$B.args"
done
MSG="$B.msg"

# reserve name, and unlock
echo "$@" > "$ARGS" || die2 "$ARGS: failed to write"
rm -f "$LOCK"

# and capture the message
echo $$ > "$MSG.pid"
cat > "$MSG"
if [ -s "$MSG" ]; then
	rm "$MSG.pid"
else
	die2 "$0: Aborted"
fi
