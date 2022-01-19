
`timescale 1 ns / 1 ps

module sha256_stream_v1_0_S00_AXIS #
       (
           // Users to add parameters here

           // User parameters ends
           // Do not modify the parameters beyond this line

           // AXI4Stream sink: Data Width
           parameter integer C_S_AXIS_TDATA_WIDTH	= 32
       )
       (
           // Users to add ports here

           input wire device_busy,
           output wire data_vaild,
           output wire[C_S_AXIS_TDATA_WIDTH-1:0] data_out,

           // User ports ends
           // Do not modify the ports beyond this line

           // AXI4Stream sink: Clock
           input wire  S_AXIS_ACLK,
           // AXI4Stream sink: Reset
           input wire  S_AXIS_ARESETN,
           // Ready to accept data in
           output wire  S_AXIS_TREADY,
           // Data in
           input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
           // Byte qualifier
           input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
           // Indicates boundary of last packet
           input wire  S_AXIS_TLAST,
           // Data is in valid
           input wire  S_AXIS_TVALID
       );
// I/O Connections assignments
assign S_AXIS_TREADY = !device_busy;
assign data_vaild = S_AXIS_TVALID;
assign data_out = S_AXIS_TDATA;

// Add user logic here

// User logic ends

endmodule
