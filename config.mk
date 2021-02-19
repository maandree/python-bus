PREFIX    = /usr/local
MANPREFIX = $(PREFIX)/share/man
PYTHONDIR = $(PREFIX)/lib/python$(PY_MAJOR).$(PY_MINOR)

CPPFLAGS  = -D_DEFAULT_SOURCE -D_BSD_SOUCE -D_XOPEN_SOURCE=700
CFLAGS    = -std=c99 -O2 $$(pkg-config --cflags python$(PY_MAJOR)) $(CPPFLAGS)
LDFLAGS   = -s $$(pkg-config --libs python$(PY_MAJOR)) -lbus

CYTHON    = cython
PYTHON    = python$(PY_MAJOR)
