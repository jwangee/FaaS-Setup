
all:
	rm -f *.tar
	tar --exclude-vcs -czf /tmp/faas-setup.tar .
	mv /tmp/faas-setup.tar .

clean:
	rm *.tar
