`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/09/04 02:42:44
// Design Name:
// Module Name: sha256_chunk_compress
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module sha256_chunk_compress(
           input clk,
           input rst_n,
           input enable,
           input update,
           input[31:0] w_in,
           input[31:0] k_in,
           output[31:0] hash0,
           output[31:0] hash1,
           output[31:0] hash2,
           output[31:0] hash3,
           output[31:0] hash4,
           output[31:0] hash5,
           output[31:0] hash6,
           output[31:0] hash7
       );

reg[31:0] h8[7:0];
reg[31:0] abcd[3:0];
reg[31:0] efgh[3:0];

wire[31:0] a;
wire[31:0] b;
wire[31:0] c;
wire[31:0] d;
wire[31:0] e;
wire[31:0] f;
wire[31:0] g;
wire[31:0] h;

wire[31:0] a_rr2;
wire[31:0] a_rr13;
wire[31:0] a_rr22;

wire[31:0] e_rr6;
wire[31:0] e_rr11;
wire[31:0] e_rr25;

wire[31:0] s0;
wire[31:0] s1;
wire[31:0] ch;
wire[31:0] maj;
wire[31:0] tmp1;
wire[31:0] tmp2;

assign a = abcd[0];
assign b = abcd[1];
assign c = abcd[2];
assign d = abcd[3];

assign e = efgh[0];
assign f = efgh[1];
assign g = efgh[2];
assign h = efgh[3];

assign a_rr2 = {a[1:0], a[31:2]};
assign a_rr13 = {a[12:0], a[31:13]};
assign a_rr22 = {a[21:0], a[31:22]};

assign e_rr6 = {e[5:0], e[31:6]};
assign e_rr11 = {e[10:0], e[31:11]};
assign e_rr25 = {e[24:0], e[31:25]};

assign s1 = e_rr6 ^ e_rr11 ^ e_rr25;
assign s0 = a_rr2 ^ a_rr13 ^ a_rr22;
assign ch = (e & f) ^ ((~e) & g);
assign maj = (a & b) ^ (a & c) ^ (b & c);
assign tmp1 = h + s1 + ch + k_in + w_in;
assign tmp2 = s0 + maj;

assign hash0 = h8[0];
assign hash1 = h8[1];
assign hash2 = h8[2];
assign hash3 = h8[3];
assign hash4 = h8[4];
assign hash5 = h8[5];
assign hash6 = h8[6];
assign hash7 = h8[7];

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        abcd[0] <= 32'h0;
    end
    else begin
        if(enable) begin
            abcd[0] <= tmp1 + tmp2;
        end
        else begin
            abcd[0] <= h8[0];
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        efgh[0] <= 32'h0;
    end
    else begin
        if(enable) begin
            efgh[0] <= d + tmp1;
        end
        else begin
            efgh[0] <= h8[4];
        end
    end
end

generate genvar i;
    for(i = 1; i < 4; i = i + 1) begin: chunk_compress_pipe
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0) begin
                abcd[i] <= 32'h0;
            end
            else begin
                if(enable) begin
                    abcd[i] <= abcd[i - 1];
                end
                else begin
                    abcd[i] <= h8[i];
                end
            end
        end

        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0) begin
                efgh[i] <= 32'h0;
            end
            else begin
                if (enable) begin
                    efgh[i] <= efgh[i - 1];
                end
                else begin
                    efgh[i] <= h8[i + 4];
                end
            end
        end
    end
endgenerate

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        h8[0] <= 32'h6a09e667;
        h8[1] <= 32'hbb67ae85;
        h8[2] <= 32'h3c6ef372;
        h8[3] <= 32'ha54ff53a;
        h8[4] <= 32'h510e527f;
        h8[5] <= 32'h9b05688c;
        h8[6] <= 32'h1f83d9ab;
        h8[7] <= 32'h5be0cd19;
    end
    else begin
        if(enable & update) begin
            h8[0] <= h8[0] + a;
            h8[1] <= h8[1] + b;
            h8[2] <= h8[2] + c;
            h8[3] <= h8[3] + d;
            h8[4] <= h8[4] + e;
            h8[5] <= h8[5] + f;
            h8[6] <= h8[6] + g;
            h8[7] <= h8[7] + h;
        end
        else begin
            h8[0] <= h8[0];
            h8[1] <= h8[1];
            h8[2] <= h8[2];
            h8[3] <= h8[3];
            h8[4] <= h8[4];
            h8[5] <= h8[5];
            h8[6] <= h8[6];
            h8[7] <= h8[7];
        end
    end
end

endmodule
