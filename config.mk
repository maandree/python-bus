PREFIX    = /usr
MANPREFIX = $(PREFIX)/share/man
PYTHONDIR = $(PREFIX)/lib/python$(PY_MAJOR).$(PY_MINOR)
PYTHONPKGDIR = $(PYTHONDIR)/site-packages

CC     = cc
CYTHON = cython
PYTHON = python$(PY_VERSION)

CPPFLAGS  = -D_DEFAULT_SOURCE -D_BSD_SOUCE -D_XOPEN_SOURCE=700
CFLAGS    = -std=c99 -O2 $$(pkg-config --cflags python$(PY_MAJOR))
LDFLAGS   = -s $$(pkg-config --libs python$(PY_MAJOR)) -lbus

PY_MAJOR   = $$(python --version 2>&1 | cut -d . -f 1 | cut -d ' ' -f 2)
PY_MINOR   = $$(python$(PYTHON_MAJOR) --version 2>&1 | cut -d . -f 2)
PY_VERSION = $(PY_MAJOR).$(PY_MINOR)
