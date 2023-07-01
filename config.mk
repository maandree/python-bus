PREFIX    = /usr
MANPREFIX = $(PREFIX)/share/man
PYTHONDIR = $(PREFIX)/lib/python$(PYTHON_MAJOR).$(PYTHON_MINOR)
PYTHONPKGDIR = $(PYTHONDIR)/site-packages

CC     = cc
CYTHON = cython$(PYTHON_MAJOR)
PYTHON = python$(PYTHON_VERSION)

CPPFLAGS  = -D_DEFAULT_SOURCE -D_BSD_SOUCE -D_XOPEN_SOURCE=700
CFLAGS    = -std=c99 -O2 $$(pkg-config --cflags python$(PYTHON_MAJOR))
LDFLAGS   = -s $$(pkg-config --libs python$(PYTHON_MAJOR)) -lbus

PYTHON_MAJOR   = $$(python --version 2>&1 | cut -d ' ' -f 2 | cut -d . -f 1)
PYTHON_MINOR   = $$(python$(PYTHON_MAJOR) --version 2>&1 | cut -d . -f 2)
PYTHON_VERSION = $(PYTHON_MAJOR).$(PYTHON_MINOR)
