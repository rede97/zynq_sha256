`timescale 1 ns / 1 ps

module sha256_axi_full_tb;

initial
begin
    $dumpfile("sha256_axi_full.vcd");        //生成的vcd文件名称
    $dumpvars(0, sha256_axi_full_tb);    //tb模块名称
    $timeformat(-9, 2, "ns", 4);
end

localparam T = 10;
localparam AXI_ID_WIDTH = 1;
localparam AXI_DATA_WIDTH = 32;
localparam AXI_ADDR_WIDTH = 8;

reg aclk;
reg aresetn;

// write address channel
reg [AXI_ID_WIDTH-1:0] axi_awid;
reg [AXI_ADDR_WIDTH-1:0] axi_awaddr;
reg [7:0] axi_awlen;
reg [2:0] axi_awsize;
reg [1:0] axi_awbrust;
reg axi_awlock;
reg [3:0] axi_awcache;
reg [2:0] axi_awprot;
reg [3:0] axi_awqos;
reg [3:0] axi_awregion;
reg axi_awvaild;
wire axi_awready;

// write data channel
reg [AXI_DATA_WIDTH-1:0] axi_wdata;
reg [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb;
reg axi_wlast;
reg axi_wvaild;
wire axi_wready;

// write response channel
wire [AXI_ID_WIDTH-1:0] axi_bid;
wire [1:0]axi_bresp;
wire axi_bvaild;
reg axi_bready;

// read address channel
reg [AXI_ID_WIDTH-1:0] axi_arid;
reg [AXI_ADDR_WIDTH-1:0] axi_araddr;
reg [7:0] axi_arlen;
reg [2:0] axi_arsize;
reg [1:0] axi_arbrust;
reg axi_arlock;
reg [3:0] axi_arcache;
reg [2:0] axi_arprot;
reg [3:0] axi_arqos;
reg [3:0] axi_arregion;
reg axi_arvaild;
wire axi_arready;

// read data channel
wire [AXI_ID_WIDTH-1:0] axi_rid;
wire [AXI_DATA_WIDTH-1:0] axi_rdata;
wire [1:0] axi_rresp;
wire axi_rlast;
wire axi_rvaild;
reg axi_rready;

initial
begin
    #0 aclk = 0;
    forever
        #(T/2) aclk = ~aclk;
end

sha256_full_v1_0 #(
                     .C_S00_AXI_ID_WIDTH(AXI_ID_WIDTH),
                     .C_S00_AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                     .C_S00_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
                 ) sha256_axi_full_inst
                 (
                     .s00_axi_aclk(aclk),
                     .s00_axi_aresetn(aresetn),
                     // read address channel
                     .s00_axi_araddr(axi_araddr[7:0]),
                     .s00_axi_arburst(axi_arbrust),
                     .s00_axi_arcache(axi_arcache),
                     .s00_axi_arid(axi_rid),
                     .s00_axi_arlen(axi_arlen),
                     .s00_axi_arlock(axi_arlock),
                     .s00_axi_arprot(axi_arprot),
                     .s00_axi_arqos(axi_arqos),
                     .s00_axi_arready(axi_arready),
                     .s00_axi_arregion(axi_arregion),
                     .s00_axi_arsize(axi_arsize),
                     .s00_axi_arvalid(axi_arvaild),
                     //  .s00_axi_aruser(0'b0),
                     // write address channel
                     .s00_axi_awaddr(axi_awaddr[7:0]),
                     .s00_axi_awburst(axi_awbrust),
                     .s00_axi_awcache(axi_awcache),
                     .s00_axi_awid(axi_awid),
                     .s00_axi_awlen(axi_awlen),
                     .s00_axi_awlock(axi_awlock),
                     .s00_axi_awprot(axi_awprot),
                     .s00_axi_awqos(axi_awqos),
                     .s00_axi_awready(axi_awready),
                     .s00_axi_awregion(axi_awregion),
                     .s00_axi_awsize(axi_awsize),
                     .s00_axi_awvalid(axi_awvaild),
                     //  .s00_axi_awuser(0'b0),
                     // write response
                     .s00_axi_bid(axi_bid),
                     .s00_axi_bready(axi_bready),
                     .s00_axi_bresp(axi_bresp),
                     .s00_axi_bvalid(axi_bvaild),
                     //  .s00_axi_buser(0'b0),
                     // read data channel
                     .s00_axi_rdata(axi_rdata),
                     .s00_axi_rid(axi_rid),
                     .s00_axi_rlast(axi_rlast),
                     .s00_axi_rready(axi_rready),
                     .s00_axi_rresp(axi_rresp),
                     .s00_axi_rvalid(axi_rvaild),
                     //  .s00_axi_ruser(0'b0),
                     // write data channel
                     .s00_axi_wdata(axi_wdata),
                     .s00_axi_wlast(axi_wlast),
                     .s00_axi_wready(axi_wready),
                     .s00_axi_wstrb(axi_wstrb),
                     .s00_axi_wvalid(axi_wvaild)
                     //  .s00_axi_wuser(0'b0),
                 );

initial begin
    aresetn = 1'b0;
    repeat(5) @(posedge aclk);

    $finish;
end
endmodule
