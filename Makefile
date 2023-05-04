EMULATOR_DIR=../emulator
BIN_TEST_DIR=test/uarch-bin
LOG_TEST_DIR=test/uarch-log
DOWNLOADDIR=downloads
BIN_TEST_VERSION=v0.28.0
LOG_TEST_VERSION=v0.14.0
BIN_DOWNLOAD_URL=https://github.com/cartesi/machine-tests/releases/download/$(BIN_TEST_VERSION)/machine-tests-$(BIN_TEST_VERSION).tar.gz
LOG_DOWNLOAD_URL=https://github.com/cartesi/machine-emulator/releases/download/$(LOG_TEST_VERSION)/uarch-riscv-tests-json-logs-$(LOG_TEST_VERSION).tar.gz

help:
	@echo 'Cleaning targets:'
	@echo '  clean                      - clean the cache artifacts'
	@echo 'Generic targets:'
	@echo '* all                        - build solidity code. To build from a clean clone, run: make submodules downloads all'
	@echo '  build                      - build solidity code'
	@echo '  deploy                     - deploy to local node'
	@echo '  generate                   - generate solidity code from cpp and template'
	@echo '  test                       - test both binary files and log files'
	@echo '  coverage                   - generate coverage report for html view'

$(DOWNLOADDIR):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(BIN_DOWNLOAD_URL) -P $(DOWNLOADDIR)
	@wget -nc $(LOG_DOWNLOAD_URL) -P $(DOWNLOADDIR)
	@shasum -ca 256 shasumfile

all: generate build test

build clean deploy:
	yarn $@

dep: $(DOWNLOADDIR)

pretest: dep
	mkdir -p $(BIN_TEST_DIR)
	mkdir -p $(LOG_TEST_DIR)
	tar -xzf $(DOWNLOADDIR)/machine-tests-${BIN_TEST_VERSION}.tar.gz -C $(BIN_TEST_DIR)
	tar -xzf $(DOWNLOADDIR)/uarch-riscv-tests-json-logs-${LOG_TEST_VERSION}.tar.gz -C $(LOG_TEST_DIR)
	rm $(BIN_TEST_DIR)/*.dump $(BIN_TEST_DIR)/*.elf

test: pretest
	forge test --via-ir -vvv

coverage: pretest
	forge coverage --via-ir --report lcov
	genhtml -o report --branch-coverage lcov.info

generate: $(EMULATOR_DIR)/src/uarch-execute-insn.h
	EMULATOR_DIR=$(EMULATOR_DIR) lua translator/generate-UArchExecuteInsn.lua
	yarn prettier -w

submodules:
	git submodule update --init --recursive

.PHONY: help all build clean coverage deploy downloads test generate submodules
