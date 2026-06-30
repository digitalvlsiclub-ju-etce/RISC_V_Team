
VERILOG_COMPILER = iverilog
SIMULATOR        = vvp
VIEWER           = gtkwave

# --- Directories ---
SRC_DIR = src
OUT_DIR = compile

# --- Files ---

SOURCES = $(wildcard $(SRC_DIR)/*.v $(SRC_DIR)/*.sv) 

# All generated files are saved in compile folder
OUTPUT_EXE = $(OUT_DIR)/sim.vvp
WAVE_DATA  = $(OUT_DIR)/waveforms.vcd
SIM_LOG    = $(OUT_DIR)/simulation_log.txt



# Default rule
all: prep sim


prep:
	@mkdir -p $(OUT_DIR)


compile: prep $(SOURCES)
	@echo "Compiling Verilog sources from $(SRC_DIR)/..."
	$(VERILOG_COMPILER) -g2012 -I $(SRC_DIR) -o $(OUTPUT_EXE) $(SOURCES)


sim: compile
	@echo "Running simulation..."
	@echo "Saving output log to $(SIM_LOG)..."
	$(SIMULATOR) $(OUTPUT_EXE) > $(SIM_LOG)


wave: sim
	@echo "Opening waveforms..."
	$(VIEWER) $(WAVE_DATA) &

# only clean compile directory
clean:
	@echo "Safely cleaning the $(OUT_DIR)/ directory..."
	rm -rf $(OUT_DIR)/*

.PHONY: all prep compile sim wave clean