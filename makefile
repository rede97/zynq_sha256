all: 
	iverilog -o wave -y ./ -Wall tb_axi_sha256.v
	vvp -n wave -lxt2

run:
	gtkwave wave.gtkw