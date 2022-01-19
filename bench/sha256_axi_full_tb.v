`timescale 1 ns / 1 ps

module sha256_axi_full_tb;

initial begin
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

// user
wire [-1:0] void_user;

wire irq_hash_finish;

initial begin
    #0 aclk = 0;
    forever
        #(T/2) aclk = ~aclk;
end

initial begin
    axi_awid = 0;
    axi_awaddr = 0;
    axi_awlen = 0;
    axi_awsize = 0;
    axi_awbrust = 0;
    axi_awlock = 0;
    axi_awcache = 0;
    axi_awprot = 0;
    axi_awqos = 0;
    axi_awvaild = 0;
    axi_awregion = 0;
    axi_wdata = 0;
    axi_wstrb = 0;
    axi_wlast = 0;
    axi_wvaild = 0;
    axi_bready = 0;
    axi_arid = 0;
    axi_araddr = 0;
    axi_arlen = 0;
    axi_arsize = 0;
    axi_arbrust = 0;
    axi_arlock = 0;
    axi_arcache = 0;
    axi_arprot = 0;
    axi_arqos = 0;
    axi_arregion = 0;
    axi_arvaild = 0;
    axi_rready = 0;
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
                     .s00_axi_aruser(void_user),
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
                     .s00_axi_awuser(void_user),
                     // write response
                     .s00_axi_bid(axi_bid),
                     .s00_axi_bready(axi_bready),
                     .s00_axi_bresp(axi_bresp),
                     .s00_axi_bvalid(axi_bvaild),
                     .s00_axi_buser(void_user),
                     // read data channel
                     .s00_axi_rdata(axi_rdata),
                     .s00_axi_rid(axi_rid),
                     .s00_axi_rlast(axi_rlast),
                     .s00_axi_rready(axi_rready),
                     .s00_axi_rresp(axi_rresp),
                     .s00_axi_rvalid(axi_rvaild),
                     .s00_axi_ruser(void_user),
                     // write data channel
                     .s00_axi_wdata(axi_wdata),
                     .s00_axi_wlast(axi_wlast),
                     .s00_axi_wready(axi_wready),
                     .s00_axi_wstrb(axi_wstrb),
                     .s00_axi_wvalid(axi_wvaild),
                     .s00_axi_wuser(void_user),
                     // irq
                     .irq_hash_finish(irq_hash_finish)
                 );

localparam BURST_FIXED = 2'b00,
           BURST_INC = 2'b01,
           BURST_WRAP = 2'b10;

task axi_wait;
    input integer n;
    begin
        repeat(n) @(posedge aclk);
    end
endtask

task axi_arclr;
    begin
        axi_araddr = 0;
        axi_arlen = 0;
        axi_arbrust = 0;
        axi_arsize = 0;
        axi_arvaild = 0;
    end
endtask

task axi_rclr;
    begin
        axi_rready = 0;
    end
endtask

task axi_awclr;
    begin
        axi_awaddr = 0;
        axi_awlen = 0;
        axi_awbrust = 0;
        axi_awsize = 0;
        axi_awvaild = 0;
    end
endtask

task axi_wclr;
    begin
        axi_wdata = 0;
        axi_wstrb = 0;
        axi_wlast = 0;
        axi_wvaild = 0;
    end
endtask

task axi_bclr;
    begin
        axi_bready = 0;
    end
endtask

reg[31:0] axi_buffer[255:0];
task axi_read;
    input [AXI_ADDR_WIDTH-3:0] raddr;
    input [7:0] rlen;
    input [1:0] burst;
    integer addr_cnt;
    begin
        axi_araddr = {raddr, 2'b00};
        axi_arlen = rlen - 1;
        axi_arbrust = burst;
        axi_arsize = 3'b010;
        axi_arvaild = 1'b1;
        addr_cnt = 0;
        // wait arready
        repeat(16) begin
            axi_wait(1);
            if (axi_arready) begin
                axi_arclr;
                // start read
                axi_rready = 1'b1;
                while(addr_cnt < rlen) begin
                    axi_wait(1);
                    if(axi_rvaild) begin
                        if(axi_rresp != 2'b00) begin
                            $display("[%m]#%t ERROR: Invaild rresp: %d", $time, axi_bresp);
                            $stop;
                        end
                        axi_buffer[addr_cnt] = axi_rdata;
                        addr_cnt = addr_cnt + 1;
                    end
                end
                axi_rclr;
                disable axi_read;
            end
        end
        $display("[%m]#%t ERROR: Timeout, wait arready", $time);
        $stop;
    end
endtask

task axi_write;
    input [AXI_ADDR_WIDTH-3:0] waddr;
    input [7:0] wlen;
    input [1:0] burst;
    integer addr_cnt;
    begin
        axi_awaddr = {waddr, 2'b00};
        axi_awlen = wlen - 1;
        axi_awbrust = burst;
        axi_awsize = 3'b010;
        axi_awvaild = 1'b1;
        addr_cnt = 0;
        // wait awready
        repeat(16) begin
            axi_wait(1);
            if(axi_awready) begin
                axi_awclr;
                // start write
                axi_wvaild = 1'b1;
                axi_wstrb = 4'b1111;
                while (addr_cnt < wlen) begin
                    if (addr_cnt + 1 == wlen) begin
                        axi_wlast = 1'b1;
                    end
                    axi_wdata = axi_buffer[addr_cnt];
                    axi_wait(1);
                    if (axi_wready) begin
                        addr_cnt = addr_cnt + 1;
                    end
                end
                axi_wclr;
                // wait bresp
                repeat(16) begin
                    axi_wait(1);
                    if(axi_bvaild) begin
                        if(axi_bresp != 2'b00) begin
                            $display("[%m]#%t ERROR: Invaild bresp: %d", $time, axi_bresp);
                            $stop;
                        end
                        axi_bready = 1'b1;
                        axi_wait(1);
                        axi_bclr;
                        disable axi_write;
                    end
                end
                $display("[%m]#%t ERROR: Timeout, wait bresp", $time);
                $stop;
            end
        end
        $display("[%m]#%t ERROR: Timeout, wait awready", $time);
        $stop;
    end
endtask

task dump_sha256_result;
    begin
        $display("[%m]#%t SHA256: %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", $time,
                 axi_buffer[0][7:0], axi_buffer[0][15:8], axi_buffer[0][23:16], axi_buffer[0][31:24],
                 axi_buffer[1][7:0], axi_buffer[1][15:8], axi_buffer[1][23:16], axi_buffer[1][31:24],
                 axi_buffer[2][7:0], axi_buffer[2][15:8], axi_buffer[2][23:16], axi_buffer[2][31:24],
                 axi_buffer[3][7:0], axi_buffer[3][15:8], axi_buffer[3][23:16], axi_buffer[3][31:24],
                 axi_buffer[4][7:0], axi_buffer[4][15:8], axi_buffer[4][23:16], axi_buffer[4][31:24],
                 axi_buffer[5][7:0], axi_buffer[5][15:8], axi_buffer[5][23:16], axi_buffer[5][31:24],
                 axi_buffer[6][7:0], axi_buffer[6][15:8], axi_buffer[6][23:16], axi_buffer[6][31:24],
                 axi_buffer[7][7:0], axi_buffer[7][15:8], axi_buffer[7][23:16], axi_buffer[7][31:24]);
    end
endtask


initial begin
    aresetn = 1'b0;
    repeat(5) @(posedge aclk);
    aresetn = 1'b1;
    axi_buffer[0] = 32'h03;
    axi_write(0, 1, BURST_INC);
    axi_buffer[0] = 32'h64343962;
    axi_buffer[1] = 32'h39623732;
    axi_buffer[2] = 32'h64343339;
    axi_buffer[3] = 32'h38306533;
    axi_buffer[4] = 32'h65323561;
    axi_buffer[5] = 32'h37643235;
    axi_buffer[6] = 32'h64376164;
    axi_buffer[7] = 32'h61666261;
    axi_buffer[8] = 32'h34383463;
    axi_buffer[9] = 32'h33656665;
    axi_buffer[10] = 32'h33356137;
    axi_buffer[11] = 32'h65653038;
    axi_buffer[12] = 32'h38383039;
    axi_buffer[13] = 32'h63613766;
    axi_buffer[14] = 32'h66653265;
    axi_buffer[15] = 32'h39656463;
    axi_buffer[16] = 32'h00000080;
    axi_buffer[17] = 32'h00000000;
    axi_buffer[18] = 32'h00000000;
    axi_buffer[19] = 32'h00000000;
    axi_buffer[20] = 32'h00000000;
    axi_buffer[21] = 32'h00000000;
    axi_buffer[22] = 32'h00000000;
    axi_buffer[23] = 32'h00000000;
    axi_buffer[24] = 32'h00000000;
    axi_buffer[25] = 32'h00000000;
    axi_buffer[26] = 32'h00000000;
    axi_buffer[27] = 32'h00000000;
    axi_buffer[28] = 32'h00000000;
    axi_buffer[29] = 32'h00000000;
    axi_buffer[30] = 32'h00000000;
    axi_buffer[31] = 32'h00020000;
    axi_write(16, 32, BURST_FIXED);
    @(posedge irq_hash_finish);
    axi_read(8, 8, BURST_INC);
    dump_sha256_result();
    $display("expect: 049da052634feb56ce6ec0bc648c672011edff1cb272b53113bbc90a8f00249c");
    axi_wait(4);
    $finish;
end
endmodule
