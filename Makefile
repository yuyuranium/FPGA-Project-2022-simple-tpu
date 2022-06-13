TOP = top
HDL = hdl
SRC = $(wildcard $(HDL)/*.v)
TESTBENCH = tb/tb.cc
VERILATOR = verilator
VERILATOR_FLAGS += -Ihdl
VERILATOR_FLAGS += -cc --exe
VERILATOR_FLAGS += --x-assign unique --x-initial unique
VERILATOR_FLAGS += --trace
# VERILATOR_FLAGS += -Wall

.dafault: run
.PHONY: run
run: obj_dir/V$(TOP)
	@echo
	@echo "--BUILD--------------"
	$(MAKE) -C obj_dir -f V$(TOP).mk
	@echo
	@echo "--RUN----------------"
	obj_dir/V$(TOP) +verilator+rand+reset+2

obj_dir/V$(TOP) obj_dir: $(SRC)
	@echo
	@echo "--VERILATE-----------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(HDL)/$(TOP).v $(TESTBENCH)

clean:
	rm -rf obj_dir
	rm -rf *.vcd
