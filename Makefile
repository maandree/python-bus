# The package path prefix, if you want to install to another root, set DESTDIR to that root
PREFIX = /usr
# The library path excluding prefix
LIB = /lib
# The resource path excluding prefix
DATA = /share
# The library path including prefix
LIBDIR = ${PREFIX}${LIB}
# The resource path including prefix
DATADIR = ${PREFIX}${DATA}
# The generic documentation path including prefix
DOCDIR = ${DATADIR}/doc
# The license base path including prefix
LICENSEDIR = ${DATADIR}/licenses


# The major version number of the current Python installation
PY_MAJOR = $(shell python -V | cut -d ' ' -f 2 | cut -d . -f 1)
# The minor version number of the current Python installation
PY_MINOR = $(shell python -V | cut -d ' ' -f 2 | cut -d . -f 2)
# The version number of the current Python installation without a dot
PY_VER = ${PY_MAJOR}${PY_MINOR}
# The version number of the current Python installation with a dot
PY_VERSION = ${PY_MAJOR}.${PY_MINOR}


# The directory for python modules
PYTHONDIR = ${LIBDIR}/python${PY_VERSION}


# The name of the package as it should be installed
PKGNAME = python-bus


# The installed pkg-config command
PKGCONFIG ?= pkg-config
# The installed cython command
CYTHON ?= cython
# The installed python command
PYTHON = python${PY_MAJOR}


# Libraries to link with using pkg-config
LIBS = python${PY_MAJOR}


# The C standard for C code compilation
STD = c99
# Optimisation settings for C code compilation
OPTIMISE = -O2


# Flags to use when compiling
CC_FLAGS = $$(${PKGCONFIG} --cflags ${LIBS}) -std=${STD} ${OPTIMISE} -fPIC ${CFLAGS} ${CPPFLAGS}

# Flags to use when linking
LD_FLAGS = $$(${PKGCONFIG} --libs ${LIBS}) -lbus -std=${STD} ${OPTIMISE} -shared ${LDFLAGS}


# The suffixless basename of the .py-files
PYTHON_SRC = bus

# The suffixless basename of the .py-files
CYTHON_SRC = native_bus


# Filename extension for -OO optimised python files
ifeq ($(shell test $(PY_VER) -ge 35 ; echo $$?),0)
PY_OPT2_EXT = opt-2.pyc
else
PY_OPT2_EXT = pyo
endif



all: pyc-files pyo-files so-files

pyc-files: $(foreach M,${PYTHON_SRC},src/__pycache__/${M}.cpython-${PY_VER}.pyc)
pyo-files: $(foreach M,${PYTHON_SRC},src/__pycache__/${M}.cpython-${PY_VER}.$(PY_OPT2_EXT))
so-files: $(foreach M,${CYTHON_SRC},bin/${M}.so)

bin/%.so: obj/%.o
	@mkdir -p bin
	${CC} ${LD_FLAGS} -o $@ $^

obj/%.o: obj/%.c
	${CC} ${CC_FLAGS} -iquote"src" -c -o $@ $<

obj/%.c: obj/%.pyx
	if ! ${CYTHON} -3 -v $< ; then rm $@ ; false ; fi

obj/%.pyx: src/%.pyx
	@mkdir -p obj
	cp $< $@

src/__pycache__/%.cpython-$(PY_VER).pyc: src/%.py
	${PYTHON} -m compileall $<

src/__pycache__/%.cpython-$(PY_VER).$(PY_OPT2_EXT): src/%.py
	${PYTHON} -OO -m compileall $<



install: install-base

install-all: install-base
install-base: install-lib install-copyright
install-lib: install-source install-compiled install-optimised install-native

install-source: $(foreach M,$(PYTHON_SRC),src/$(M).py)
	install -dm755 -- "$(DESTDIR)$(PYTHONDIR)"
	install -m644 $^ -- "$(DESTDIR)$(PYTHONDIR)"

install-compiled: $(foreach M,$(PYTHON_SRC),src/__pycache__/$(M).cpython-$(PY_VER).pyc)
	install -dm755 -- "$(DESTDIR)$(PYTHONDIR)/__pycache__"
	install -m644 $^ -- "$(DESTDIR)$(PYTHONDIR)/__pycache__"

install-optimised: $(foreach M,$(PYTHON_SRC),src/__pycache__/$(M).cpython-$(PY_VER).$(PY_OPT2_EXT))
	install -dm755 -- "$(DESTDIR)$(PYTHONDIR)/__pycache__"
	install -m644 $^ -- "$(DESTDIR)$(PYTHONDIR)/__pycache__"

install-native: $(foreach M,$(CYTHON_SRC),bin/$(M).so)
	install -dm755 -- "$(DESTDIR)$(PYTHONDIR)"
	install -m755 $^ -- "$(DESTDIR)$(PYTHONDIR)"

install-copyright: install-license

install-license: LICENSE
	install -dm755 -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	install -m644 $^ -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"



uninstall:
	-rm -- "${DESTDIR}${LICENSEDIR}/${PKGNAME}/LICENSE"
	-rmdir -- "${DESTDIR}${LICENSEDIR}/${PKGNAME}"
	-rm -- $(foreach M,${PYTHON_SRC},"${DESTDIR}${PYTHONDIR}/__pycache__/${M}.cpython-${PY_VER}.$(PY_OPT2_EXT)")
	-rm -- $(foreach M,${PYTHON_SRC},"${DESTDIR}${PYTHONDIR}/__pycache__/${M}.cpython-${PY_VER}.pyc")
	-rm -- $(foreach M,${PYTHON_SRC},"${DESTDIR}${PYTHONDIR}/${M}.py")
	-rm -- $(foreach M,${CYTHON_SRC},"${DESTDIR}${PYTHONDIR}/${M}.so")



clean:
	-rm -r obj bin src/__pycache__



.PHONY: all pyc-files pyo-files so-files install install-all install-base \
        install-lib install-source install-compiled install-optimised \
        install-native install-copyright install-license uninstall clean

