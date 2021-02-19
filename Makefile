.POSIX:

CONFIGFILE = config.mk
include $(CONFIGFILE)

PY_MAJOR   = $$(python --version 2>&1 | cut -d . -f 1 | cut -d ' ' -f 2)
PY_MINOR   = $$(python$(PYTHON_MAJOR) --version 2>&1 | cut -d . -f 2)


all: native_bus.so

native_bus.so: native_bus.o
	$(CC) -o $@ native_bus.o -shared $(LDFLAGS)

.c.o:
	$(CC) -fPIC -c -o $@ $< $$(pkg-config --cflags python$(PY_MAJOR)) $(CFLAGS) $(CPPFLAGS)

.pyx.c:
	if ! $(CYTHON) -$(PY_MAJOR) -v $< -o $@ ; then rm $@; false; fi

install: native_bus.so
	mkdir -p -- "$(DESTDIR)$(PYTHONDIR)/site-packages"
	cp -- bus.py native_bus.so "$(DESTDIR)$(PYTHONDIR)/site-packages"

uninstall:
	-rm -f -- "$(DESTDIR)$(PYTHONDIR)/site-packages/native_bus.so"
	-rm -f -- "$(DESTDIR)$(PYTHONDIR)/site-packages/bus"

clean:
	-rm -rf -- __pycache__ *.pyc *.pyo *.o *.so

.SUFFIXES:
.SUFFIXES: .o .c .pyx

.PHONY: all install uninstall clean
