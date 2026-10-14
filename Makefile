VERILATOR ?= verilator

.PHONY: lint lint-matrix
lint:
	$(VERILATOR) --lint-only --Wall --top-module amba_ahb_lite_sram -f amba_ahb_lite.f
	$(VERILATOR) --lint-only --Wall --top-module amba_ahb_lite_interconnect -f amba_ahb_lite.f

lint-matrix: lint
	@set -e; for width in 8 16 32 64 128 256 512 1024; do \
	    for endian in 0 1; do \
	        $(VERILATOR) --lint-only --Wall --top-module amba_ahb_lite_sram \
	            -f amba_ahb_lite.f -GDataWidth=$$width -GBigEndian=$$endian; \
	    done; \
	done
	@set -e; for depth in 1 3 256; do \
	    for waits in 0 1 16 20; do \
	        $(VERILATOR) --lint-only --Wall --top-module amba_ahb_lite_sram \
	            -f amba_ahb_lite.f -GDepthWords=$$depth -GWaitStates=$$waits -GBaseAddr=1024; \
	    done; \
	done
