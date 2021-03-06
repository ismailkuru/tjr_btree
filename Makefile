DUNE:=dune

build:
	$(DUNE) build @install
#	$(DUNE) build examples/*.exe
# FIXME	$(DUNE) build test_bin/all.touch

install:
	$(DUNE) install

uninstall:
	$(DUNE) uninstall

clean:
	$(DUNE) clean
	rm -f examples/btree.store
	rm -f test_bin/btree.store

# NOTE prefer to build doc with all repos
# doc: FORCE
# 	$(DUNE) build @doc

run_examples:
	$(MAKE) -C examples -f Makefile.run_examples

run_tests:
	$(MAKE) -C test_bin -f Makefile.run_tests

FORCE:


