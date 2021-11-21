all: 
	iverilog -o wave -y ./ -Wall tb_axi_sha256.v
	vvp -n wave

run:
	gtkwave wave.gtkw