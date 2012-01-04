S=/usr/lib/sendmail /usr/sbin/sendmail
D=$(PWD)/sendmail.sh

.PHONY: $(S)

all:

install: $(S)

$(S):
	[ -e $@ ] || ln -snvf "$D" $@
