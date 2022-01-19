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
           input compress_start,
           input update_hash,
           input in_vaild,
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

reg[31:0] H8[7:0];
reg[31:0] abcdefgh[7:0];

reg[31:0] stage[2:0];

wire[31:0] h8_next[7:0];
wire[31:0] abcdefgh_next[7:0];

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

wire[31:0] compress;

assign a = abcdefgh_next[0];
assign b = abcdefgh_next[1];
assign c = abcdefgh_next[2];
assign d = abcdefgh_next[3];
assign e = abcdefgh_next[4];
assign f = abcdefgh_next[5];
assign g = abcdefgh_next[6];
assign h = abcdefgh_next[7];

assign a_rr2 = {a[1:0], a[31:2]};
assign a_rr13 = {a[12:0], a[31:13]};
assign a_rr22 = {a[21:0], a[31:22]};
assign s0 = a_rr2 ^ a_rr13 ^ a_rr22;
assign maj = (a & b) ^ (a & c) ^ (b & c);

assign e_rr6 = {e[5:0], e[31:6]};
assign e_rr11 = {e[10:0], e[31:11]};
assign e_rr25 = {e[24:0], e[31:25]};
assign s1 = e_rr6 ^ e_rr11 ^ e_rr25;
assign ch = (e & f) ^ ((~e) & g);

assign tmp1 = stage[0];
assign tmp2 = stage[1] + stage[2];
assign compress = tmp1 + tmp2;

assign abcdefgh_next[0] = compress_start ? compress : H8[0];
assign abcdefgh_next[1] = compress_start ? abcdefgh[0] : H8[1];
assign abcdefgh_next[2] = compress_start ? abcdefgh[1] : H8[2];
assign abcdefgh_next[3] = compress_start ? abcdefgh[2] : H8[3];
assign abcdefgh_next[4] = compress_start ? abcdefgh[3] + tmp2 : H8[4];
assign abcdefgh_next[5] = compress_start ? abcdefgh[4] : H8[5];
assign abcdefgh_next[6] = compress_start ? abcdefgh[5] : H8[6];
assign abcdefgh_next[7] = compress_start ? abcdefgh[6] : H8[7];

function [31:0]lsb_to_msb;
    input [31:0]lsb;
    lsb_to_msb = {lsb[7:0], lsb[15:8], lsb[23:16], lsb[31:24]};
endfunction

assign hash0 = lsb_to_msb(H8[0]);
assign hash1 = lsb_to_msb(H8[1]);
assign hash2 = lsb_to_msb(H8[2]);
assign hash3 = lsb_to_msb(H8[3]);
assign hash4 = lsb_to_msb(H8[4]);
assign hash5 = lsb_to_msb(H8[5]);
assign hash6 = lsb_to_msb(H8[6]);
assign hash7 = lsb_to_msb(H8[7]);

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        stage[0] <= 32'h0;
        stage[1] <= 32'h0;
        stage[2] <= 32'h0;
    end
    else begin
        if(in_vaild) begin
            // preload 'compress' signal
            stage[0] <= s0 + maj;
            stage[1] <= s1 + ch;
            stage[2] <= w_in + k_in + h;
        end
        else begin
            stage[0] <= stage[0];
            stage[1] <= stage[1];
            stage[2] <= stage[2];
        end
    end
end

generate genvar i;
    for(i = 0; i < 8; i = i + 1) begin: chunk_compress_pipe
        always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                abcdefgh[i] <= 32'h0;
            end
            else begin
                if(in_vaild) begin
                    abcdefgh[i] <= abcdefgh_next[i];
                end
                else begin
                    abcdefgh[i] <= abcdefgh[i];
                end
            end
        end
        assign h8_next[i] = update_hash ? H8[i] + abcdefgh_next[i] : H8[i];
    end
endgenerate

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        H8[0] <= 32'h6a09e667;
        H8[1] <= 32'hbb67ae85;
        H8[2] <= 32'h3c6ef372;
        H8[3] <= 32'ha54ff53a;
        H8[4] <= 32'h510e527f;
        H8[5] <= 32'h9b05688c;
        H8[6] <= 32'h1f83d9ab;
        H8[7] <= 32'h5be0cd19;
    end
    else begin
        H8[0] <= h8_next[0];
        H8[1] <= h8_next[1];
        H8[2] <= h8_next[2];
        H8[3] <= h8_next[3];
        H8[4] <= h8_next[4];
        H8[5] <= h8_next[5];
        H8[6] <= h8_next[6];
        H8[7] <= h8_next[7];
    end
end

endmodule
