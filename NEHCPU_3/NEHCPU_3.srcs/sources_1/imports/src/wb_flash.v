//allow read only
module flash_top(
    // Parallel FLASH Interface
    input              wb_clk_i,
    input              wb_rst_i,
    output wire [22:0] lamp,
    input              wb_stb_i,
    input              wb_cyc_i,
    output reg         wb_ack_o,
    input      [31: 0] wb_adr_i,
    input      [ 3: 0] wb_sel_i,
    input              wb_we_i,
    input      [31: 0] wb_dat_i,
    output reg [31: 0] wb_dat_o,
    output reg [22:0] flash_adr_o, 
    inout   [15:0] flash_dat_io, 
    output [7:0] flash_ctrl
);

    assign lamp = flash_adr_o;
    //
    // Default address and data bus width
    //
    parameter FLASH_ADDR_SIZE = 22;   // input:21:0 -> flash:{input,1'b0}
    parameter FLASH_DATA_SIZE = 16;
    parameter WORD_SIZE = 32;   


    // Wishbone read/write accesses
    wire wb_acc = wb_cyc_i & wb_stb_i;    // WISHBONE access
    wire wb_wr  = wb_acc & wb_we_i;       // WISHBONE write access
    wire wb_rd  = wb_acc & ~wb_we_i;      // WISHBONE read access


    reg flash_oe, flash_we;
    wire flash_byte = 1, flash_vpen = 1, flash_rp = 1;
    wire flash_ce;
    assign flash_ce = ~wb_acc;
    //assign flash_oe = !wb_rd;
    //assign flash_we = !wb_wr;
    assign flash_ctrl = {
        flash_byte,
        flash_ce,
        2'b0,   // ce1 ce2
        flash_oe,
        flash_rp,
        flash_vpen,
        flash_we};

    reg [15:0] data_to_write;//, data_in_latch;
    assign flash_dat_io = flash_oe ? data_to_write : {16{1'bz}};


    //assign flash_rst = !wb_rst_i;

    reg [3:0] waitstate;            //Áä∂Ê?ÅÊú∫   
    //wire    [1:0] adr_low;

    
    always @(posedge wb_clk_i) begin
        if( wb_rst_i == 1'b1 ) begin
            waitstate <= 4'h0;
            wb_ack_o <= 1'b0;
            flash_oe <= 1;
            flash_we <= 1;
        end else if(wb_acc == 1'b0) begin
            waitstate <= 4'h0;
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'h00000000;
            flash_oe <= 1;
            flash_we <= 1;
        end else if(waitstate == 4'h0) begin
            wb_ack_o <= 1'b0;
            if (wb_rd) begin
                data_to_write <= 16'h00FF;
                flash_oe <= 1;
                flash_we <= 0;
                waitstate <= waitstate + 4'h1;
                flash_adr_o <= {wb_adr_i[FLASH_ADDR_SIZE:2],1'b0};
            end
            
        end else begin
            waitstate <= waitstate + 4'h1;
            if (waitstate == 4'h1) begin
                flash_we <= 1;
            end else if (waitstate == 4'h2) begin
                flash_oe <= 0;
            end else if (waitstate == 4'hf) begin
                flash_oe <= 1;
                wb_ack_o <= 1'b1;
                wb_dat_o <= {{16{1'b0}}, flash_dat_io};
                waitstate <= 4'h0;
            end 
        end
    end

    

endmodule
