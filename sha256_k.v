`timescale 1ns / 1ps

module sha256_k(
    input enable,
    input[5:0] addr,
    output[31:0] k_o
);

reg[31:0] rom_k[63:0];


initial begin
    $readmemb("sha256_k.mif", rom_k);
    $display("%08x", rom_k[0]);
end

assign k_o = enable ? rom_k[addr] : 32'h0;

endmodule