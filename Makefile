# This -Wall was supported by the European Commission through the ERC Starting Grant 805031 (EPOQUE)
CFLAGS=-Wall -Wextra -Wpedantic -Werror -std=c99 $(EXTRAFLAGS)

bin/functest_$(subst /,_,$(SCHEME)): $(dir $(SCHEME))test.c $(wildcard $(SCHEME)/clean/*.c) $(wildcard $(SCHEME)/clean/*.h) | require_scheme
	mkdir -p bin
	$(CC) $(CFLAGS) \
		-iquote "./common/" \
		-iquote "$(SCHEME)/clean/" \
		-o bin/functest_$(subst /,_,$(SCHEME)) \
		common/*.c \
		$(SCHEME)/clean/*.c \
		$<

.PHONY: functest
functest: bin/functest_$(subst /,_,$(SCHEME))

.PHONY: run-functest
run-functest: bin/functest_$(subst /,_,$(SCHEME))
	./$<

.PHONY: clean
clean:
	rm -rf bin

.PHONY: format
format:
	find . -iname *.h -o -iname *.c | xargs clang-format -i -style=file

.PHONY: tidy
tidy: require_scheme
	clang-tidy \
		$(SCHEME)/clean/*.c \
		$(SCHEME)/../test.c \
		common/*.c \
		$(.TIDY_FIX) \
		-- -iquote "common/" -iquote "$(SCHEME)/clean"

.PHONY: fix-tidy
apply-tidy: | $(eval .TIDY_FIX = -fix) tidy

.PHONY: help
help:
	@echo make functest SCHEME=scheme	run functional tests for SCHEME
	@echo make clean					clean up the bin/ folder
	@echo make format					Automatically formats all the source code
	@echo make tidy SCHEME=scheme  		Runs the clang-tidy linter against SCHEME
	@echo make fix-tidy SCHEME=scheme	Tries to automatically fix the issues found by clang-tidy in SCHEME
	@echo make help						Displays this message

.PHONY: require_scheme
require_scheme:
# assumes a SCHEME variable; e.g. make functest_kem SCHEME=crypto_kem/kyber768
ifndef SCHEME
	$(error The SCHEME variable is not set. Example: SCHEME=crypto_kem/kyber768)
endif

.PHONY: build-functests
build-functests:
	find crypto_kem/ crypto_sign/ -mindepth 1 -maxdepth 1 -type d -exec make functest SCHEME={} \;

.PHONY: run-functests
run-functests:
	find crypto_kem/ crypto_sign/ -mindepth 1 -maxdepth 1 -type d -exec make run-functest SCHEME={} \;

.PHONY: test-all
test-all: run-functests

.PHONY: tidy-all
tidy-all:
	find crypto_kem/ crypto_sign/ -mindepth 1 -maxdepth 1 -type d -exec make tidy SCHEME={} \;

.PHONY: applytidy-all
apply-tidy-all:
	find crypto_kem/ crypto_sign/ -mindepth 1 -maxdepth 1 -type d -exec make apply-tidy SCHEME={} \;
