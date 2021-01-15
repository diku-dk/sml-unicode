MLLIB=lib/github.com/diku-dk/sml-unicode
FILENAMES=test/unicode_test.mlb test/unicode.sml unicode.mlb UTF8.sig Utf8.sml UNICODE_CHARS.sig UnicodeChars.sml
FILES=$(FILENAMES:%=$(MLLIB)/%)
MLCOMP ?= mlton

.PHONY: build
build:
	@echo "No binaries to build."
	@echo "Run 'make test' to run an acceptance test."

$(MLLIB)/test/unicode_test.exe: $(FILES)
	$(MLCOMP) -output $@ $<

.PHONY: all
all: $(MLLIB)/test/unicode_test.exe

.PHONY: test
test: $(MLLIB)/test/unicode_test.exe
	@echo "Running test..."
	@(cd $(MLLIB)/test; ./unicode_test.exe > unicode_test.out)
	@[[ `diff $(MLLIB)/test/unicode_test.ok $(MLLIB)/test/unicode_test.out` ]] && \
           (echo "***Test failed***") || \
           (echo "Test succeeded.")

.PHONY: install
install:
	@echo "No binaries to install"

.PHONY: clean
clean:
	rm -rf *~ MLB $(MLLIB)/test/unicode_test.exe $(MLLIB)/*.out $(MLLIB)/MLB $(MLLIB)/*~
	rm -rf $(MLLIB)/test/*.out $(MLLIB)/test/MLB $(MLLIB)/test/*~
