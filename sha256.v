`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2020/09/02 01:13:24
// Design Name:
// Module Name: sha256
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

// `include "sha256_chunk_compress.v"
// `include "sha256_chunk_process.v"
// `include "sha256_k.v"


module sha256(
           input clk,
           input rst_n,
           input dat_vaild_i,
           input [31:0] dat_lsb_i,
           output [31:0] hash0,
           output [31:0] hash1,
           output [31:0] hash2,
           output [31:0] hash3,
           output [31:0] hash4,
           output [31:0] hash5,
           output [31:0] hash6,
           output [31:0] hash7,
           output wire hash_busy_o,
           output reg irq_finish
       );

localparam  IDLE = 0,
            LOAD = 1,
            PROC = 2,
            FINISH = 3;

reg[1:0] state;
reg[1:0] state_next;
reg[7:0] counter;

wire[7:0] counter_nxt;
wire[31:0] dat_msb_i;
wire[5:0] k_addr;
wire chunk_clr;
wire[31:0] k_out;
wire[31:0] w_out;
wire state_is_proc;
wire update_hash;

assign k_addr = counter[5:0] - 6'h10;
assign update_hash = counter == 8'h50;
assign hash_busy_o = state == PROC | state == FINISH;
assign chunk_clr = (~dat_vaild_i & (state == IDLE)) | state == FINISH;
assign state_is_proc = state == PROC;
assign dat_msb_i = {dat_lsb_i[7:0], dat_lsb_i[15:8], dat_lsb_i[23:16], dat_lsb_i[31:24]};

assign counter_nxt = dat_vaild_i | state_is_proc ? counter + 8'h1 : counter;
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n | chunk_clr)
    begin
        counter <= 8'h0;
    end
    else
    begin
        counter <= counter_nxt;
    end
end

sha256_chunk_process sha256_chunk_process_u0(
                         .clk(clk),
                         .rst_n(rst_n),
                         .clear(chunk_clr),
                         .process_start(state_is_proc),
                         .dat_vaild_i(dat_vaild_i),
                         .dat_msb_i(dat_msb_i),
                         .w_out(w_out)
                     );

sha256_k sha256_k_u1(
             .enable(state_is_proc),
             .addr(k_addr),
             .k_o(k_out)
         );

//sha256_k sha256_k_u1 (
//  .a(k_addr),              // input wire [5 : 0] a
//  .qspo_ce(state_is_proc),  // input wire qspo_ce
//  .spo(k_out)          // output wire [31 : 0] spo
//);

sha256_chunk_compress sha256_chunk_compress_u2(
                          .clk(clk),
                          .rst_n(rst_n),
                          .proc_start(state_is_proc),
                          .update_hash(update_hash),
                          .w_in(w_out),
                          .k_in(k_out),
                          .hash0(hash0),
                          .hash1(hash1),
                          .hash2(hash2),
                          .hash3(hash3),
                          .hash4(hash4),
                          .hash5(hash5),
                          .hash6(hash6),
                          .hash7(hash7)
                      );

always@(posedge clk or negedge rst_n)
begin
    if (rst_n == 1'b0)
    begin
        state <= IDLE;
    end
    else
    begin
        state <= state_next;
    end
end

always@(*)
begin
    if(rst_n == 1'b0)
    begin
        state_next = IDLE;
    end
    else
    begin
        case(state)
            default: begin
                state_next = IDLE;
            end
            IDLE:
            begin
                if(dat_vaild_i)
                begin
                    state_next = LOAD;
                end
                else
                begin
                    state_next = state;
                end
            end
            LOAD:
            begin
                if(counter == 8'h10)
                begin
                    state_next = PROC;
                end
                else
                begin
                    state_next = state;
                end
            end
            PROC:
            begin
                if(update_hash)
                begin
                    state_next = FINISH;
                end
                else
                begin
                    state_next = state;
                end
            end
            FINISH:
            begin
                state_next = IDLE;
            end
        endcase
    end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n) begin
        irq_finish <= 1'b0;
    end else begin
        irq_finish <= state == FINISH;
    end
end

endmodule
