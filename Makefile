.POSIX:

CONFIGFILE = config.mk
include $(CONFIGFILE)


all: native_bus.so

.o.so:
	$(CC) -o $@ $< -shared $(LDFLAGS)

.c.o:
	$(CC) -fPIC -c -o $@ $< $(CFLAGS) $(CPPFLAGS)

.pyx.c:
	if ! $(CYTHON) -$(PY_MAJOR) -v $< -o $@ ; then rm $@; false; fi

install: native_bus.so
	mkdir -p -- "$(DESTDIR)$(PYTHONPKGDIR)"
	cp -- bus.py native_bus.so "$(DESTDIR)$(PYTHONPKGDIR)/"

uninstall:
	-rm -f -- "$(DESTDIR)$(PYTHONPKGDIR)/native_bus.so"
	-rm -f -- "$(DESTDIR)$(PYTHONPKGDIR)/bus"

clean:
	-rm -rf -- __pycache__ *.pyc *.pyo *.o *.so

.SUFFIXES:
.SUFFIXES: .so .o .c .pyx

.PHONY: all install uninstall clean
