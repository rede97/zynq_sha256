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
           input clear,
           input proc_ninit,
           input dat_vaild_i,
           input[31:0] dat_msb_i,
           output[31:0] w_out
       );

reg[31:0] W[15:0];
wire[31:0] w_in;
wire[31:0] w_new;
wire enable;

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
wire[31:0] s0;
wire[31:0] s1;

assign enable = dat_vaild_i | proc_ninit;

assign w_m15 = W[1];
assign w_m15_rr7 = {w_m15[6:0], w_m15[31:7]};
assign w_m15_rr18 = {w_m15[17:0], w_m15[31:18]};
assign w_m15_r3 = w_m15 >> 3;

assign w_m2 = W[14];
assign w_m2_rr17 = {w_m2[16:0], w_m2[31:17]};
assign w_m2_rr19 = {w_m2[18:0], w_m2[31:19]};
assign w_m2_r10 = w_m2 >> 10;

assign w_m16 = W[0];
assign w_m7 = W[9];

assign s0 = w_m15_rr7 ^ w_m15_rr18 ^ w_m15_r3;
assign s1 = w_m2_rr17 ^ w_m2_rr19 ^ w_m2_r10;
assign w_new = w_m16 + s0 + w_m7 + s1;

assign w_in = proc_ninit ? w_new : dat_msb_i;
assign w_out = W[0];



always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 | clear) begin
        W[15] <= 32'h0;
    end
    else begin
        if(enable) begin
            W[15] <= w_in;
            $display("[%m]#%t INFO: Load: 0x%08x", $time, w_in);
        end else begin
            W[15] <= W[15];
        end
    end
end

generate genvar i;
    for(i = 0; i < 15; i = i + 1) begin: chunk_proc_pipeline
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0 | clear) begin
                W[i] <= 32'h0;
            end
            else begin
                if(enable) begin 
                    W[i] <= W[i + 1];
                end else begin
                    W[i] <= W[i];
                end
            end
        end
    end
endgenerate

endmodule
