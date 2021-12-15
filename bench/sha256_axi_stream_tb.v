`timescale 1 ns / 1 ps

// `include "sha256_v1_0_S00_AXI.v"

module sha256_axi_stream_tb;

initial begin
    $dumpfile("sha256_axi_stream_tb.vcd");        //生成的vcd文件名称
    $dumpvars(0, sha256_axi_stream_tb);    //tb模块名称
    $timeformat(-9, 2, "ns", 4);
end

localparam T = 10;

reg aclk;
reg aresetn;

wire s_axi_aclk;
wire s_axi_aresetn;

assign s_axi_aclk = aclk;
assign s_axi_aresetn = aresetn;

// read address
wire s_axi_arready;
reg [5:0] s_axi_araddr;
reg s_axi_arvalid;

// write address
wire s_axi_awready;
reg [5:0] s_axi_awaddr;
reg s_axi_awvalid;

// write response
reg s_axi_bready;
wire [1:0] s_axi_bresp;
wire s_axi_bvalid;

// read data
reg s_axi_rready;
wire [31:0] s_axi_rdata;
wire [1:0] s_axi_rresp;
wire s_axi_rvalid;

// write data
wire s_axi_wready;
reg [31:0] s_axi_wdata;
reg [3:0] s_axi_wstrb;
reg s_axi_wvalid;

wire axis_tready;
reg [31:0] axis_tdata;
reg [3:0] axis_tstrb;
reg axis_tlast;
reg axis_tvaild;

sha256_stream_v1_0 # (
                       .C_S00_AXI_DATA_WIDTH(32),
                       .C_S00_AXI_ADDR_WIDTH(6),
                       .C_S00_AXIS_TDATA_WIDTH(32)
                   ) sha256_stream_v1_0_inst (
                       .s00_axi_aclk(s_axi_aclk),
                       .s00_axi_aresetn(s_axi_aresetn),
                       .s00_axi_awaddr(s_axi_awaddr),
                       .s00_axi_awprot(3'h0),
                       .s00_axi_awvalid(s_axi_awvalid),
                       .s00_axi_awready(s_axi_awready),
                       .s00_axi_wdata(s_axi_wdata),
                       .s00_axi_wstrb(s_axi_wstrb),
                       .s00_axi_wvalid(s_axi_wvalid),
                       .s00_axi_wready(s_axi_wready),
                       .s00_axi_bresp(s_axi_bresp),
                       .s00_axi_bvalid(s_axi_bvalid),
                       .s00_axi_bready(s_axi_bready),
                       .s00_axi_araddr(s_axi_araddr),
                       .s00_axi_arprot(3'h0),
                       .s00_axi_arvalid(s_axi_arvalid),
                       .s00_axi_arready(s_axi_arready),
                       .s00_axi_rdata(s_axi_rdata),
                       .s00_axi_rresp(s_axi_rresp),
                       .s00_axi_rvalid(s_axi_rvalid),
                       .s00_axi_rready(s_axi_rready),
                       .s00_axis_aclk(s_axi_aclk),
                       .s00_axis_aresetn(s_axi_aresetn),
                       .s00_axis_tready(axis_tready),
                       .s00_axis_tdata(axis_tdata),
                       .s00_axis_tstrb(axis_tstrb),
                       .s00_axis_tlast(axis_tlast),
                       .s00_axis_tvalid(axis_tvaild)
                   );

task axil_wait;
    input integer n;
    begin
        repeat(n) @(posedge aclk);
    end
endtask

task axil_read;
    input [29:0] addr;
    output [31:0] value;
    reg [31:0] temp_addr;
    begin
        s_axi_araddr = {addr, 2'b00};
        temp_addr = s_axi_araddr;
        // $display("[%m]#%t INFO: Read Addr: 0x%08x", $time, temp_addr);
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
                    // $display("[%m]#%t INFO: Read Value: 0x%08x @ 0x%08x -> [resp: %d]", $time, s_axi_rdata, temp_addr, s_axi_rresp);
                    value = s_axi_rdata;
                end
                else begin
                    $display("[%m]#%t ERROR: Read Invaild @ 0x%08x -> [resp: %d]", $time, temp_addr, s_axi_rresp);
                    value = 32'h00000000;
                end

                axil_wait(1);
                disable axil_read;
            end
        end

        $display("[%m]#%t ERROR: Timeout, ARREADY must be 1 @ 0x%08x", $time, temp_addr);

        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        axil_wait(1);
    end
endtask

task axil_write;
    input [29:0] addr;
    input [31:0] data;
    integer awready_ok;
    integer wready_ok;
    reg [31:0] temp_addr;
    begin
        awready_ok = 0;
        wready_ok = 0;

        s_axi_awvalid = 1;
        s_axi_awaddr = {addr, 2'b00};
        temp_addr = s_axi_awaddr;
        // $display("[%m]#%t INFO: Write Data: 0x%08x to 0x%08x", $time, data, temp_addr);

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
                    // $display("[%m]#%t INFO: Write Data: 0x%08x => 0x%08x -> [resp: %d]", $time, data, temp_addr, s_axi_bresp);
                end
                else begin
                    $display("[%m]#%t Error: Write Invaild: 0x%08x to 0x%08x -> [resp: %d]", $time, temp_addr, data, s_axi_bresp);
                end

                axil_wait(1);
                disable axil_write;
            end
        end

        if(awready_ok) begin
            $display("[%m]#%t ERROR: Timeout, AWREADY must be 1 @ 0x%08x", $time, temp_addr);
        end
        if(wready_ok) begin
            $display("[%m]#%t ERROR: Timeout, WREADY must be 1 @ 0x%08x", $time, temp_addr);
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

reg [31:0]axis_buffer[64:0];
task axis_write;
    input[5:0] wlen;
    integer cnt;
    begin
        axis_tvaild = 1'b1;
        axis_tstrb = 4'b1111;
        cnt = 0;
        while (cnt < wlen) begin
            if(cnt + 1 == wlen) begin
                axis_tlast = 1'b1;
            end
            axis_tdata = axis_buffer[cnt];
            axil_wait(1);
            if(axis_tready) begin
                cnt = cnt + 1;
            end
        end
        axis_tvaild = 0;
        axis_tstrb = 0;
        axis_tlast = 0;
        axis_tdata = 0;
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

    axis_tdata = 0;
    axis_tlast = 0;
    axis_tvaild = 0;
    axis_tstrb = 0;

    #0 aresetn = 0;
    axil_wait(3);
    aresetn = 1;
end

reg [31:0]sha256_result[7:0];
task dump_sha256_result;
    begin
        $display("[%m]#%t SHA256: %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", $time,
                 sha256_result[0][7:0], sha256_result[0][15:8], sha256_result[0][23:16], sha256_result[0][31:24],
                 sha256_result[1][7:0], sha256_result[1][15:8], sha256_result[1][23:16], sha256_result[1][31:24],
                 sha256_result[2][7:0], sha256_result[2][15:8], sha256_result[2][23:16], sha256_result[2][31:24],
                 sha256_result[3][7:0], sha256_result[3][15:8], sha256_result[3][23:16], sha256_result[3][31:24],
                 sha256_result[4][7:0], sha256_result[4][15:8], sha256_result[4][23:16], sha256_result[4][31:24],
                 sha256_result[5][7:0], sha256_result[5][15:8], sha256_result[5][23:16], sha256_result[5][31:24],
                 sha256_result[6][7:0], sha256_result[6][15:8], sha256_result[6][23:16], sha256_result[6][31:24],
                 sha256_result[7][7:0], sha256_result[7][15:8], sha256_result[7][23:16], sha256_result[7][31:24]);
    end
endtask

initial begin
    @(posedge aresetn);
    axil_wait(3);
    axil_write(32'h00, 32'b11);

    axis_buffer[0] = 32'h64343962;
    axis_buffer[1] = 32'h39623732;
    axis_buffer[2] = 32'h64343339;
    axis_buffer[3] = 32'h38306533;
    axis_buffer[4] = 32'h65323561;
    axis_buffer[5] = 32'h37643235;
    axis_buffer[6] = 32'h64376164;
    axis_buffer[7] = 32'h61666261;
    axis_buffer[8] = 32'h34383463;
    axis_buffer[9] = 32'h33656665;
    axis_buffer[10] = 32'h33356137;
    axis_buffer[11] = 32'h65653038;
    axis_buffer[12] = 32'h38383039;
    axis_buffer[13] = 32'h63613766;
    axis_buffer[14] = 32'h66653265;
    axis_buffer[15] = 32'h39656463;
    axis_buffer[16] = 32'h00000080;
    axis_buffer[17] = 32'h00000000;
    axis_buffer[18] = 32'h00000000;
    axis_buffer[19] = 32'h00000000;
    axis_buffer[20] = 32'h00000000;
    axis_buffer[21] = 32'h00000000;
    axis_buffer[22] = 32'h00000000;
    axis_buffer[23] = 32'h00000000;
    axis_buffer[24] = 32'h00000000;
    axis_buffer[25] = 32'h00000000;
    axis_buffer[26] = 32'h00000000;
    axis_buffer[27] = 32'h00000000;
    axis_buffer[28] = 32'h00000000;
    axis_buffer[29] = 32'h00000000;
    axis_buffer[30] = 32'h00000000;
    axis_buffer[31] = 32'h00020000;
    axis_write(32);


    axil_wait(70);
    axil_read(32'h08, sha256_result[0]);
    axil_read(32'h09, sha256_result[1]);
    axil_read(32'h0a, sha256_result[2]);
    axil_read(32'h0b, sha256_result[3]);
    axil_read(32'h0c, sha256_result[4]);
    axil_read(32'h0d, sha256_result[5]);
    axil_read(32'h0e, sha256_result[6]);
    axil_read(32'h0f, sha256_result[7]);
    axil_wait(8);

    dump_sha256_result();
    $display("expect: 049da052634feb56ce6ec0bc648c672011edff1cb272b53113bbc90a8f00249c");
    $finish;
end

endmodule
