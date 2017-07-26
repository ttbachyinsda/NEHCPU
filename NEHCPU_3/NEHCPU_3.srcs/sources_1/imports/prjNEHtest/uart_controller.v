`include "defines.v"

module uart_controller (
    input wire CLK,
    input wire RESET,
    output wire SOUT,
    input wire SIN,
    output reg UART_ACK_O,
    input wire[3:0] UART_SEL_I,
    input wire UART_CYC_I,
    input wire UART_STB_I,
    input wire UART_WE_I,
    output reg[31:0] UART_DAT_O,
    input wire [31:0] UART_DAT_I,
    input wire [31:0] UART_ADR_I,
    output reg INTR
);

    wire write_busy;
    reg txd_start;
    reg [7:0] txd_data;
    wire [7:0] fifo_dout;
    reg fifo_rd;
    wire fifo_empty;
    wire data_ready;
    wire[7:0] rxd_data;
    wire full;
    // Wishbone read/write accesses
    wire wb_acc = UART_CYC_I & UART_STB_I;    // WISHBONE access
    wire wb_wr  = wb_acc & UART_WE_I;       // WISHBONE write access
    wire wb_rd  = wb_acc & ~UART_WE_I;      // WISHBONE read access
    always @(posedge CLK) begin
        fifo_rd <= 0;
        txd_start <= 0;
        UART_ACK_O <= 1;
        UART_DAT_O <= 32'b0;
        txd_data <= 8'b0;
        if (wb_acc == 1) begin
            if (UART_WE_I == 1) begin
                if (UART_ADR_I[2:0] == 3'b000) begin
                    if (write_busy == 0) begin
                        txd_data <= UART_DAT_I[7:0];
                        txd_start <= 1;
                    end else begin
                        UART_ACK_O <= 0;
                    end
                 end
             end
            else begin
                if (UART_ADR_I[2:0] == 3'b000) begin
                    UART_DAT_O[31:8] <= 24'b0;
                    UART_DAT_O[7:0] <= fifo_dout;
                    fifo_rd <= 1;
                end
                else begin
                    UART_DAT_O[31:2] <= 30'b0;
                    UART_DAT_O[0] <= ~write_busy;
                    UART_DAT_O[1] <= ~fifo_empty;
                end
            end
        end else UART_ACK_O <= 0;
        INTR <= ~fifo_empty;
    end
    uart_async_transmitter txd (.clk(CLK), /* .rst(rst), */
        .TxD(SOUT), .TxD_data(txd_data),
        .TxD_start(txd_start),
        .TxD_busy(write_busy)
    );
    uart_async_receiver rxd (.clk(CLK), .rst(RESET),
        .RxD(SIN), .RxD_data_ready(data_ready),
        .RxD_data(rxd_data)
    );
    fifo_wrapper fifo0(
        .clk(CLK),
        .rst(RESET),
        .din(rxd_data),
        .wr_en(data_ready),
        .rd_en(fifo_rd),
        .dout(fifo_dout),
        .full(full),
        .empty(fifo_empty)
    );

 endmodule // uart_controller
