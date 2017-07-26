`timescale 1ns / 1ps

module vga_slave
(
    input clk,
    output wire hsync,
    output wire vsync,
    output wire data_enable,
    output wire[31:0]   lamp,
        input              clk_i,
        input              rst_i,
        input              wb_stb_i,
        input              wb_cyc_i,
        output reg         wb_ack_o,
        input      [31: 0] wb_addr_i,
        input      [ 3: 0] wb_sel_i,
        input              wb_we_i,
        input      [31: 0] wb_data_i,
        output reg [31: 0] wb_data_o,
    
        // VGA interface.
        output reg[2:0] red_o,
        output reg[2:0] green_o,
        output reg[2:0] blue_o
);
reg [`WIDTH - 1:0] hdata;
reg [`WIDTH - 1:0] vdata;
// init
initial begin
    hdata <= 0;
    vdata <= 0;
end
    wire wb_acc = wb_cyc_i & wb_stb_i;    // WISHBONE access
    wire wb_wr  = wb_acc & wb_we_i;       // WISHBONE write access
    wire wb_rd  = wb_acc & ~wb_we_i;      // WISHBONE read access
    reg offset_we_i;
    reg [8:0] offset_i;

    reg [3:0] waitstate;            //çŠ¶æ?æœº   
    reg[17:0] vga_addr;
    reg[8:0] vga_in_data;
    wire[8:0] vga_out_data;
    reg we_i;
    assign lamp = {8'b0, offset_i};
    //assign lamp = {16'b0,wb_cyc_i,wb_acc,wb_stb_i,wb_we_i,vga_addr[3:0],offset_i};
    
    always @(posedge clk_i) begin
        if( rst_i == 1'b1 ) begin
            waitstate <= 4'h0;
            wb_ack_o <= 1'b0;
            we_i <= 0;
        end else if(wb_acc == 1'b0) begin
            waitstate <= 4'h0;
            wb_ack_o <= 1'b0;
            wb_data_o <= 32'h00000000;
            we_i <= 0;
            offset_we_i <= 0;
        end else if(waitstate == 4'h0) begin
            wb_ack_o <= 1'b0;
            if ({wb_addr_i[19:2],2'b0} == 20'h96000) begin
               if (wb_rd) begin
                   offset_we_i <= 0;
                   waitstate <= waitstate + 4'h1;
               end else if (wb_wr) begin
                   offset_we_i <= 1;
                   offset_i <= wb_data_i[8:0];
                   waitstate <= waitstate + 4'h1;
               end
            end else begin
               if (wb_rd) begin
                   we_i <= 0;
                   waitstate <= waitstate + 4'h1;
                   vga_addr <= wb_addr_i[19:2];
               end else if (wb_wr) begin
                   we_i <= 1;
                   waitstate <= waitstate + 4'h1;
                   vga_addr <= wb_addr_i[19:2];
                   vga_in_data <= wb_data_i[8:0];
               end
            end
            
        end else begin
            
                if ({wb_addr_i[19:2],2'b0} == 20'h96000) begin
                    if (waitstate == 4'h1) begin
                        wb_ack_o <= 1'b1;
                        wb_data_o <= {{23{1'b0}}, offset_i};
                        waitstate <= 4'h0;
                        offset_we_i <= 0;
                    end
                end else begin
                    if (waitstate == 4'h1) begin
                        wb_ack_o <= 1'b1;
                        wb_data_o <= {{23{1'b0}}, vga_out_data};
                        waitstate <= 4'h0;
                        we_i <= 0;
                    end
                end
            waitstate <= waitstate + 4'h1;
        end
    end
// hdata
reg[`VGA_OFFSET_BUS] scan_offset;
wire[`VGA_ADDR_BUS] vga_scan_addr;

wire[`VGA_OFFSET_BUS] vscan_bottom;
wire[`VGA_OFFSET_BUS] vscan_offset;
assign vscan_bottom = 300 - scan_offset;
assign vscan_offset = (vdata[9:1] >= vscan_bottom) ? (vdata[9:1] - vscan_bottom) :
    (scan_offset + vdata[9:1]);
assign vga_scan_addr = {vscan_offset, 9'b0} + hdata[10:1];
vga_ram vga_ram0 (
    .wea(we_i),
    .clka(clk), .addra(vga_addr), .dina(vga_in_data),
    .clkb(clk), .addrb(vga_scan_addr), .doutb(vga_out_data)
);
always @ (posedge clk)
begin
    if (hdata == (`HMAX - 1))
        hdata <= 0;
    else
        hdata <= hdata + 1;
end
always @ ( posedge clk ) begin
    if (rst_i == 1) begin
        scan_offset <= 0;
    end else begin
        if (offset_we_i == 1) begin
            scan_offset <= offset_i;
           end
    end
end
// vdata
always @ (posedge clk)
begin
    if (hdata == (`HMAX - 1)) 
    begin
        if (vdata == (`VMAX - 1))
            vdata <= 0;
        else
            vdata <= vdata + 1;
    end
end
always @ ( posedge clk ) begin
        if (rst_i == 1)
            {red_o, green_o, blue_o} <= 9'b0;
        else
            {red_o, green_o, blue_o} <= vga_out_data;
end
//assign red_o = hdata;
//assign {blue_o[2:1],green_o} = vdata;
// hsync & vsync & blank
assign hsync = ((hdata >= `HFP) && (hdata < `HSP)) ? `HSPP : !`HSPP;
assign vsync = ((vdata >= `VFP) && (vdata < `VSP)) ? `VSPP : !`VSPP;
assign data_enable = ((hdata < `HSIZE) & (vdata < `VSIZE));

endmodule
