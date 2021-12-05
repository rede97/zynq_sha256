
V ?= @

RUN_DIR = $(shell pwd)
LOG_DIR = $(shell pwd)/sim/log
OUT_DIR = $(shell pwd)/sim/out

WORK_DIR = ..
TEST_DIR = .
WORK_SOURCES = $(wildcard $(WORK_DIR)/*.v)
TEST_SOURCES = $(wildcard $(TEST_DIR)/*.v)

TESTBENCH_SOURCES = $(shell ls $(TEST_DIR)/*_tb.v)
TESTBENCHES = $(shell echo $(TESTBENCH_SOURCES) | sed 's:$(TEST_DIR)/::g' | sed 's:\.v::g')

all: $(OUT_DIR) $(LOG_DIR) simulate

$(OUT_DIR):
	$(V)mkdir -p $@

$(LOG_DIR):
	$(V)mkdir -p $@

print_work_sources:
	$(V)@echo $(WORK_SOURCES)

print_test_sources:
	$(V)@echo $(TEST_SOURCES)
	
print_testbenches:
	$(V)@echo $(TESTBENCHES)

clean: sim_clean
	$(V)rm -rfv sim
