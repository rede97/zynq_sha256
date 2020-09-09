`timescale 1 ns / 1 ps

`include "sha256_v1_0_S00_AXI.v"

module tc_axi_sha256;

initial begin
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, tc_axi_sha256);    //tb模块名称
    $timeformat(-9, 2, "ns", 4);
end

localparam T = 10;

reg aclk;
reg aresetn;

wire s_axi_aclk;
wire s_axi_aresetn;

assign s_axi_aclk = aclk;
assign s_axi_aresetn = aresetn;

wire s_axi_arready;
reg [3:0] s_axi_araddr;
reg s_axi_arvalid;

wire s_axi_awready;
reg [3:0] s_axi_awaddr;
reg s_axi_awvalid;

reg s_axi_bready;
wire [1:0] s_axi_bresp;
wire s_axi_bvalid;

reg s_axi_rready;
wire [31:0] s_axi_rdata;
wire [1:0] s_axi_rresp;
wire s_axi_rvalid;

wire s_axi_wready;
reg [31:0] s_axi_wdata;
reg [3:0] s_axi_wstrb;
reg s_axi_wvalid;


sha256_v1_0_S00_AXI # (
                        .C_S_AXI_DATA_WIDTH(32),
                        .C_S_AXI_ADDR_WIDTH(4)
                    ) sha256_v1_0_S00_AXI_inst (
                        .S_AXI_ACLK(s_axi_aclk),
                        .S_AXI_ARESETN(s_axi_aresetn),
                        .S_AXI_AWADDR(s_axi_awaddr),
                        .S_AXI_AWPROT(3'h0),
                        .S_AXI_AWVALID(s_axi_awvalid),
                        .S_AXI_AWREADY(s_axi_awready),
                        .S_AXI_WDATA(s_axi_wdata),
                        .S_AXI_WSTRB(s_axi_wstrb),
                        .S_AXI_WVALID(s_axi_wvalid),
                        .S_AXI_WREADY(s_axi_wready),
                        .S_AXI_BRESP(s_axi_bresp),
                        .S_AXI_BVALID(s_axi_bvalid),
                        .S_AXI_BREADY(s_axi_bready),
                        .S_AXI_ARADDR(s_axi_araddr),
                        .S_AXI_ARPROT(3'h0),
                        .S_AXI_ARVALID(s_axi_arvalid),
                        .S_AXI_ARREADY(s_axi_arready),
                        .S_AXI_RDATA(s_axi_rdata),
                        .S_AXI_RRESP(s_axi_rresp),
                        .S_AXI_RVALID(s_axi_rvalid),
                        .S_AXI_RREADY(s_axi_rready)
                    );

task axil_wait;
    input integer n;
    begin
        repeat(n) @(posedge aclk);
    end
endtask

task axil_read;
    input [31:0] addr;
    begin
        $display("[%m]#%t INFO: Read Addr: 0x%08x", $time, addr);
        s_axi_araddr = addr;
        s_axi_arvalid = 1;
        s_axi_rready = 1;
        repeat(4) begin
            axil_wait(1);
            if(s_axi_arready) begin
                s_axi_araddr = 0;
                s_axi_arvalid = 0;
                axil_wait(1);
                s_axi_rready = 0;
                if(s_axi_rvalid) begin
                    $display("[%m]#%t INFO: Read Value: 0x%08x @ 0x%08x -> [resp: %d]", $time, s_axi_rdata, addr, s_axi_rresp);
                end
                else begin
                    $display("[%m]#%t ERROR: Read Invaild @ 0x%08x -> [resp: %d]", $time, addr, s_axi_rresp);
                end

                axil_wait(1);
                disable axil_read;
            end
        end

        $display("[%m]#%t ERROR: Timeout, ARREADY must be 1 @ 0x%08x", $time, addr);

        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        axil_wait(1);
    end
endtask

task axil_write;
    input [31:0] addr;
    input [31:0] data;
    integer awready_ok;
    integer wready_ok;
    begin
        $display("[%m]#%t INFO: Write Data: 0x%08x to 0x%08x", $time, data, addr);
        awready_ok = 0;
        wready_ok = 0;

        s_axi_awvalid = 1;
        s_axi_awaddr = addr;

        s_axi_wvalid = 1;
        s_axi_wdata = data;
        s_axi_wstrb = 4'b1111;

        s_axi_bready = 1;
        repeat(4) begin
            axil_wait(1);
            if(s_axi_awready) begin
                awready_ok = 1;
                s_axi_awvalid = 0;
                s_axi_awaddr = 0;
            end
            if(s_axi_wready) begin
                wready_ok = 1;
                s_axi_wvalid = 0;
                s_axi_wdata = 0;
                s_axi_wstrb = 0;
            end
            if(wready_ok & awready_ok) begin
                axil_wait(1);
                s_axi_bready = 0;
                if(s_axi_bvalid) begin
                    $display("[%m]#%t INFO: Write Data: 0x%08x => 0x%08x -> [resp: %d]", $time, data, addr, s_axi_bresp);
                end
                else begin
                    $display("[%m]#%t Error: Write Invaild: 0x%08x to 0x%08x -> [resp: %d]", $time, addr, data, s_axi_bresp);
                end

                axil_wait(1);
                disable axil_write;
            end
        end

        if(awready_ok) begin
            $display("[%m]#%t ERROR: Timeout, AWREADY must be 1 @ 0x%08x", $time, addr);
        end
        if(wready_ok) begin
            $display("[%m]#%t ERROR: Timeout, WREADY must be 1 @ 0x%08x", $time, addr);
        end

        s_axi_awvalid = 0;
        s_axi_awaddr = 0;

        s_axi_wvalid = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = 0;

        s_axi_bready = 0;

        axil_wait(1);
    end
endtask

initial begin
    #0 aclk = 0;
    forever
        #(T/2) aclk = ~aclk;
end

initial begin
    s_axi_araddr = 0;
    s_axi_arvalid = 0;

    s_axi_awaddr = 0;
    s_axi_awvalid = 0;

    s_axi_bready = 0;

    s_axi_rready = 0;

    s_axi_wdata = 0;
    s_axi_wstrb = 0;
    s_axi_wvalid = 0;

    #0 aresetn = 0;
    axil_wait(3);
    aresetn = 1;
end

initial begin
    @(posedge aresetn);
    axil_wait(3);
    axil_write(32'h01, 32'hbad);

    // axil_wait(3);
    axil_read(32'h01);


    axil_wait(5);
    $stop;
end

endmodule
