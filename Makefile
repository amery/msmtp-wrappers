S=/usr/lib/sendmail /usr/sbin/sendmail
D=$(PWD)/sendmail.sh

.PHONY: $(S) all install check

all:

check:
	@for x in $S; do \
		ls -al $$x; \
	done

install: $(S)

$(S):
	[ -e $@ ] || ln -snvf "$D" $@
