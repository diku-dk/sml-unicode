MLLIB=lib/github.com/diku-dk/sml-unicode
MLCOMP ?= mlkit

.PHONY: all
all:
	$(MAKE) -C $(MLLIB)/test unicode_test.exe

.PHONY: test
test:
	$(MAKE) -C $(MLLIB)/test test

.PHONY: clean
clean:
	$(MAKE) -C $(MLLIB)/test clean
	rm -rf *~ MLB $(MLLIB)/MLB $(MLLIB)/*~
