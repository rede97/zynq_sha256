
`timescale 1 ns / 1 ps

module sha256_stream_v1_0 #
       (
           // Users to add parameters here

           // User parameters ends
           // Do not modify the parameters beyond this line


           // Parameters of Axi Slave Bus Interface S00_AXI
           parameter integer C_S00_AXI_DATA_WIDTH	= 32,
           parameter integer C_S00_AXI_ADDR_WIDTH	= 6,

           // Parameters of Axi Slave Bus Interface S00_AXIS
           parameter integer C_S00_AXIS_TDATA_WIDTH	= 32
       )
       (
           // Users to add ports here

           // User ports ends
           // Do not modify the ports beyond this line


           // Ports of Axi Slave Bus Interface S00_AXI
           input wire  s00_axi_aclk,
           input wire  s00_axi_aresetn,
           input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
           input wire [2 : 0] s00_axi_awprot,
           input wire  s00_axi_awvalid,
           output wire  s00_axi_awready,
           input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
           input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
           input wire  s00_axi_wvalid,
           output wire  s00_axi_wready,
           output wire [1 : 0] s00_axi_bresp,
           output wire  s00_axi_bvalid,
           input wire  s00_axi_bready,
           input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
           input wire [2 : 0] s00_axi_arprot,
           input wire  s00_axi_arvalid,
           output wire  s00_axi_arready,
           output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
           output wire [1 : 0] s00_axi_rresp,
           output wire  s00_axi_rvalid,
           input wire  s00_axi_rready,

           // Ports of Axi Slave Bus Interface S00_AXIS
           input wire  s00_axis_aclk,
           input wire  s00_axis_aresetn,
           output wire  s00_axis_tready,
           input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
           input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
           input wire  s00_axis_tlast,
           input wire  s00_axis_tvalid
       );

wire sha256_rst_n;
wire sha256_soft_reset;
wire sha256_data_vaild_i;
wire sha256_hash_busy_o;
wire [31:0]sha256_reg_status;
wire [31:0]sha256_reg_status_nxt;
wire [31:0]sha256_lsb_data_i;
wire [31:0]sha256_result[7:0];
wire sha256_irq_finish;

// Instantiation of Axi Bus Interface S00_AXI
sha256_stream_v1_0_S00_AXI # (
                               .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
                               .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
                           ) sha256_stream_v1_0_S00_AXI_inst (
                               // User
                               .slv_reg0_o(sha256_reg_status),
                               .slv_reg0_nxt(sha256_reg_status_nxt),
                               .hash0(sha256_result[0]),
                               .hash1(sha256_result[1]),
                               .hash2(sha256_result[2]),
                               .hash3(sha256_result[3]),
                               .hash4(sha256_result[4]),
                               .hash5(sha256_result[5]),
                               .hash6(sha256_result[6]),
                               .hash7(sha256_result[7]),
                               // AXI
                               .S_AXI_ACLK(s00_axi_aclk),
                               .S_AXI_ARESETN(s00_axi_aresetn),
                               .S_AXI_AWADDR(s00_axi_awaddr),
                               .S_AXI_AWPROT(s00_axi_awprot),
                               .S_AXI_AWVALID(s00_axi_awvalid),
                               .S_AXI_AWREADY(s00_axi_awready),
                               .S_AXI_WDATA(s00_axi_wdata),
                               .S_AXI_WSTRB(s00_axi_wstrb),
                               .S_AXI_WVALID(s00_axi_wvalid),
                               .S_AXI_WREADY(s00_axi_wready),
                               .S_AXI_BRESP(s00_axi_bresp),
                               .S_AXI_BVALID(s00_axi_bvalid),
                               .S_AXI_BREADY(s00_axi_bready),
                               .S_AXI_ARADDR(s00_axi_araddr),
                               .S_AXI_ARPROT(s00_axi_arprot),
                               .S_AXI_ARVALID(s00_axi_arvalid),
                               .S_AXI_ARREADY(s00_axi_arready),
                               .S_AXI_RDATA(s00_axi_rdata),
                               .S_AXI_RRESP(s00_axi_rresp),
                               .S_AXI_RVALID(s00_axi_rvalid),
                               .S_AXI_RREADY(s00_axi_rready)
                           );

// Instantiation of Axi Bus Interface S00_AXIS
sha256_stream_v1_0_S00_AXIS # (
                                .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
                            ) sha256_stream_v1_0_S00_AXIS_inst (
                                // User
                                .device_busy(sha256_hash_busy_o),
                                .data_vaild(sha256_data_vaild_i),
                                .data_out(sha256_lsb_data_i),
                                // AXI Stream
                                .S_AXIS_ACLK(s00_axis_aclk),
                                .S_AXIS_ARESETN(s00_axis_aresetn),
                                .S_AXIS_TREADY(s00_axis_tready),
                                .S_AXIS_TDATA(s00_axis_tdata),
                                .S_AXIS_TSTRB(s00_axis_tstrb),
                                .S_AXIS_TLAST(s00_axis_tlast),
                                .S_AXIS_TVALID(s00_axis_tvalid)
                            );

// Add user logic here
assign sha256_soft_reset = sha256_reg_status[0];
assign sha256_rst_n = ~sha256_soft_reset & s00_axi_aresetn & s00_axis_aresetn;
assign sha256_reg_status_nxt = {16'h0, 7'h0, sha256_hash_busy_o, 6'h0, sha256_reg_status[1], 1'b0};

sha256 sha256_inst(
           .clk(s00_axi_aclk),
           .rst_n(sha256_rst_n),
           .dat_vaild_i(sha256_data_vaild_i),
           .dat_lsb_i(sha256_lsb_data_i),
           .hash0(sha256_result[0]),
           .hash1(sha256_result[1]),
           .hash2(sha256_result[2]),
           .hash3(sha256_result[3]),
           .hash4(sha256_result[4]),
           .hash5(sha256_result[5]),
           .hash6(sha256_result[6]),
           .hash7(sha256_result[7]),
           .hash_busy_o(sha256_hash_busy_o),
           .irq_finish(sha256_irq_finish)
       );

// User logic ends

endmodule
