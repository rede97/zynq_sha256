`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/09/03 02:44:47
// Design Name:
// Module Name: sha256_chunk_process
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


module sha256_chunk_process(
           input clk,
           input rst_n,
           input process_start,
           input dat_vaild_i,
           input[31:0] dat_msb_i,
           output[31:0] w_out,
           output w_out_vaild
       );

reg[31:0] W[15:0];
reg[31:0] s0;
reg[31:0] s1;

wire[31:0] w_in;
wire[31:0] w_new;

wire[31:0] s0_next;
wire[31:0] s1_next;
wire[31:0] W_next[15:0];
wire pipeline_start;

wire[31:0] w_m15;
wire[31:0] w_m15_rr7;
wire[31:0] w_m15_rr18;
wire[31:0] w_m15_r3;
wire[31:0] w_m2;
wire[31:0] w_m2_rr17;
wire[31:0] w_m2_rr19;
wire[31:0] w_m2_r10;
wire[31:0] w_m16;
wire[31:0] w_m7;

assign pipeline_start = dat_vaild_i | process_start;
assign w_out_vaild = pipeline_start;

assign w_m16 = W[0];

assign w_m15 = W[1 + 1];
assign w_m15_rr7 = {w_m15[6:0], w_m15[31:7]};
assign w_m15_rr18 = {w_m15[17:0], w_m15[31:18]};
assign w_m15_r3 = w_m15 >> 3;

assign s0_next = pipeline_start ? w_m15_rr7 ^ w_m15_rr18 ^ w_m15_r3 : s0;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        s0 <= 32'h0;
    end
    else begin
        s0 <= s0_next;
    end
end

assign w_m7 = W[9];

assign w_m2 = W[15];
assign w_m2_rr17 = {w_m2[16:0], w_m2[31:17]};
assign w_m2_rr19 = {w_m2[18:0], w_m2[31:19]};
assign w_m2_r10 = w_m2 >> 10;

assign s1_next = pipeline_start ? w_m2_rr17 ^ w_m2_rr19 ^ w_m2_r10 : s1;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        s1 <= 32'h0;
    end
    else begin
        s1 <= s1_next;
    end
end

assign w_new = (w_m16 + s0) + (w_m7 + s1);

assign w_in = process_start ? w_new : dat_msb_i;
assign w_out = w_in;

assign W_next[15] = pipeline_start ? w_in : W[15];
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        W[15] <= 32'h0;
    end
    else begin
        W[15] <= W_next[15];
    end
end

generate genvar i;
    for(i = 0; i < 15; i = i + 1) begin: chunk_proc_pipeline
        assign W_next[i] = pipeline_start ? W[i + 1] : W[i];
        always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                W[i] <= 32'h0;
            end
            else begin
                W[i] <= W_next[i];
            end
        end
    end
endgenerate

endmodule
