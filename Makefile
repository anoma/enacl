REBAR=rebar3
RUN_EQC=erl -pa _build/default/lib/enacl/ebin -noshell -s enacl_eqc -s init stop

.PHONY: compile
compile:
	$(REBAR) compile

.PHONY: libsodium
libsodium: libsodium/install/lib/libsodium.a

libsodium/install/lib/libsodium.a: libsodium/Makefile
	(cd libsodium;  $(MAKE) -j install)

libsodium/Makefile: libsodium/configure
	(cd libsodium; ./configure --prefix=`pwd`/install --disable-pie)

libsodium/configure:
	curl -L https://github.com/jedisct1/libsodium/releases/download/1.0.19-RELEASE/libsodium-1.0.19.tar.gz | zcat | tar xf -
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
