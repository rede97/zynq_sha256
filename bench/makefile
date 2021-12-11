TOOL ?= MODELSIM

include mkconfig/common.mk

ifeq ($(TOOL), MODELSIM) 
include mkconfig/modelsim.mk
else
include mkconfig/iverilog.mk
endif
