.POSIX:
PREFIX = ${HOME}/.local
.PHONY: install uninstall
NAME = arkiver

$(NAME):
	cp arkiver.sh $(NAME)

install: $(NAME)
	chmod 755 $(NAME)
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -vf $(NAME) ${DESTDIR}${PREFIX}/bin
	ln -sf $(NAME) ${DESTDIR}${PREFIX}/bin/ext
	ln -sf $(NAME) ${DESTDIR}${PREFIX}/bin/arls
uninstall:
	rm -vf ${DESTDIR}${PREFIX}/bin/$(NAME)
	rm -vf ${DESTDIR}${PREFIX}/bin/ext
clean:
	rm -vrf $(NAME)

