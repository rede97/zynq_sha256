`timescale 1ns / 1ps

module sha256_k(
           input enable,
           input[5:0] addr,
           output[31:0] k_o
       );

reg[31:0] rom_k[63:0];


initial begin
    rom_k[0] = 32'h428a2f98;
    rom_k[1] = 32'h71374491;
    rom_k[2] = 32'hb5c0fbcf;
    rom_k[3] = 32'he9b5dba5;
    rom_k[4] = 32'h3956c25b;
    rom_k[5] = 32'h59f111f1;
    rom_k[6] = 32'h923f82a4;
    rom_k[7] = 32'hab1c5ed5;
    rom_k[8] = 32'hd807aa98;
    rom_k[9] = 32'h12835b01;
    rom_k[10] = 32'h243185be;
    rom_k[11] = 32'h550c7dc3;
    rom_k[12] = 32'h72be5d74;
    rom_k[13] = 32'h80deb1fe;
    rom_k[14] = 32'h9bdc06a7;
    rom_k[15] = 32'hc19bf174;
    rom_k[16] = 32'he49b69c1;
    rom_k[17] = 32'hefbe4786;
    rom_k[18] = 32'h0fc19dc6;
    rom_k[19] = 32'h240ca1cc;
    rom_k[20] = 32'h2de92c6f;
    rom_k[21] = 32'h4a7484aa;
    rom_k[22] = 32'h5cb0a9dc;
    rom_k[23] = 32'h76f988da;
    rom_k[24] = 32'h983e5152;
    rom_k[25] = 32'ha831c66d;
    rom_k[26] = 32'hb00327c8;
    rom_k[27] = 32'hbf597fc7;
    rom_k[28] = 32'hc6e00bf3;
    rom_k[29] = 32'hd5a79147;
    rom_k[30] = 32'h06ca6351;
    rom_k[31] = 32'h14292967;
    rom_k[32] = 32'h27b70a85;
    rom_k[33] = 32'h2e1b2138;
    rom_k[34] = 32'h4d2c6dfc;
    rom_k[35] = 32'h53380d13;
    rom_k[36] = 32'h650a7354;
    rom_k[37] = 32'h766a0abb;
    rom_k[38] = 32'h81c2c92e;
    rom_k[39] = 32'h92722c85;
    rom_k[40] = 32'ha2bfe8a1;
    rom_k[41] = 32'ha81a664b;
    rom_k[42] = 32'hc24b8b70;
    rom_k[43] = 32'hc76c51a3;
    rom_k[44] = 32'hd192e819;
    rom_k[45] = 32'hd6990624;
    rom_k[46] = 32'hf40e3585;
    rom_k[47] = 32'h106aa070;
    rom_k[48] = 32'h19a4c116;
    rom_k[49] = 32'h1e376c08;
    rom_k[50] = 32'h2748774c;
    rom_k[51] = 32'h34b0bcb5;
    rom_k[52] = 32'h391c0cb3;
    rom_k[53] = 32'h4ed8aa4a;
    rom_k[54] = 32'h5b9cca4f;
    rom_k[55] = 32'h682e6ff3;
    rom_k[56] = 32'h748f82ee;
    rom_k[57] = 32'h78a5636f;
    rom_k[58] = 32'h84c87814;
    rom_k[59] = 32'h8cc70208;
    rom_k[60] = 32'h90befffa;
    rom_k[61] = 32'ha4506ceb;
    rom_k[62] = 32'hbef9a3f7;
    rom_k[63] = 32'hc67178f2;
end

assign k_o = enable ? rom_k[addr] : 32'h0;

endmodule
