
%_tb: $(WORK_SOURCES) $(TEST_SOURCES)
	$(v)@echo -e "\t[IV]\t" $@.v
	$(V)iverilog -y $(WORK_DIR) -y $(TEST_DIR) -I $(WORK_DIR) -s $@ -o$@ $@.v
	$(v)@echo -e "\t[VVP]\t" $@
	$(V)vvp -n $@ -lxt2
	-$(V)mv *.vcd $(OUT_DIR);
	-$(V)mv *.log $(LOG_DIR);

simulate: $(TESTBENCHES)

sim_clean:
	$(V)rm -rfv $(TESTBENCHES)