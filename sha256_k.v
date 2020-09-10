`timescale 1ns / 1ps

module sha256_k(
    input enable,
    input[5:0] addr,
    output[31:0] k_o
);

reg[31:0] rom_k[63:0];

integer fp;
integer i, n;
initial begin
    fp = $fopen("sha256_k.txt", "r");
    i = 0;
    while (!($feof(fp)) && i < 64) begin
        n = $fscanf(fp, "%x", rom_k[i]);
//        $display("rom[%2d]:%x", i, rom_k[i]);
        i = i + n;
    end
    $fclose(fp);
end

assign k_o = enable ? rom_k[addr] : 32'h0;

endmodule