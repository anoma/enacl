REBAR=rebar3
RUN_EQC=erl -pa _build/default/lib/enacl/ebin -noshell -s enacl_eqc -s init stop
HASH=018d79fe0a045cca07331d37bd0cb57b2e838c51bc48fd837a1472e50068bbea \*libsodium-1.0.19.tar.gz

# detect if this machine is arm64
ifneq ($(OS),Windows_NT)
    UNAME_P := $(shell uname -p)
    ifneq ($(filter arm%,$(UNAME_P)),)
        EXTRA_CFLAGS=-march=armv8-a+crypto+aes
    endif
endif

.PHONY: compile
compile:
	$(REBAR) compile

.PHONY: libsodium
libsodium: libsodium/install/lib/libsodium.a

libsodium/install/lib/libsodium.a: libsodium/Makefile
	(cd libsodium;  $(MAKE) -j install)

libsodium/Makefile: libsodium/configure
		(cd libsodium; env CFLAGS="$$CFLAGS $(EXTRA_CFLAGS)" ./configure --prefix=`pwd`/install --disable-pie)

libsodium/configure:
	curl -OL https://github.com/jedisct1/libsodium/releases/download/1.0.19-RELEASE/libsodium-1.0.19.tar.gz
	if [ `uname` = Darwin ]; then echo $(HASH) | shasum -a 256 -c -; else echo $(HASH) | sha256sum -c -; fi
	tar xf libsodium-1.0.19.tar.gz
	mv libsodium-stable libsodium

.PHONY: tests
tests:
	$(REBAR) ct

eqc_compile: compile
	erlc -o _build/default/lib/enacl/ebin eqc_test/enacl_eqc.erl

eqc_mini_compile: compile
	erlc -Dmini -o _build/default/lib/enacl/ebin eqc_test/enacl_eqc.erl

eqc_run: eqc_compile
	$(RUN_EQC)

eqc_mini_run: eqc_mini_compile
	$(RUN_EQC)

.PHONE: console
console: compile
	$(REBAR) shell

.PHONY: clean
clean:
	$(REBAR) clean
