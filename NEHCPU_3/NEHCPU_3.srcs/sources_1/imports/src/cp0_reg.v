`timescale 1ns / 1ps
`include "defines.v"

module cp0_reg (
   
    input wire clk,    // Clock
    input wire rst,  // Asynchronous reset active low
    
    input wire we_i,
    input wire[4: 0] waddr_i,
    input wire[4: 0] raddr_i,
    input wire[`RegBus] data_i,

    // exception
    input wire[7: 0] int_i, // interupt from peripherals and software
    input wire[31:0] excepttype_i,  
    input wire[`RegBus] current_inst_addr_i,
    input wire[`RegBus] unaligned_addr_i,
    input wire is_in_delayslot_i,
    // tlb exception
    // input wire is_tlb_modify,
    // input wire is_tlbl_data,
    // input wire is_tlbs,
    input wire[`RegBus] badvaddr_i,
    output wire[`RegBus] exc_vec_addr_o,

    output reg[`RegBus] data_o,

    output reg[`RegBus] index_o,
    output reg[`RegBus] entrylo0_o,
    output reg[`RegBus] entrylo1_o,
    output reg[`RegBus] badvaddr_o,
    output reg[`RegBus] count_o,
    output reg[`RegBus] entryhi_o,
    output reg[`RegBus] compare_o,
    output reg[`RegBus] status_o,
    output reg[`RegBus] cause_o,
    output reg[`RegBus] epc_o,
    output reg[`RegBus] ebase_o,

    output reg timer_int_o

);
	assign exc_vec_addr_o = {2'b10, ebase_o[29:12], 12'b0};

    always @(posedge clk) begin 
        if(rst == `RstEnable) begin
            index_o <= `ZeroWord;
            entrylo0_o <= `ZeroWord;
            entrylo1_o <= `ZeroWord;
            badvaddr_o <= `ZeroWord;
            count_o <= `ZeroWord;
            entryhi_o <= `ZeroWord;
            compare_o <= `ZeroWord;
            status_o <= 32'h10400004; //CU0 = 1, BEV = 1, ERL = 1
            cause_o<= `ZeroWord;
            epc_o <= `ZeroWord;
            ebase_o <= 32'h80000000;
            timer_int_o <= 1'b0;
        end 
        else begin
            count_o <= count_o + 1;
            cause_o[15: 8] <= int_i;
        
            if(compare_o != `ZeroWord && count_o == compare_o) begin
                timer_int_o <= 1'b1;
            end

            if(we_i == `WriteEnable) begin
                case (waddr_i)
                    `CP0_REG_INDEX: begin 
                        index_o[3: 0] <= data_i[3: 0];
                    end
                    `CP0_REG_ENTRYLO0: begin 
                        entrylo0_o[25: 6] <= data_i[25: 6];
                        entrylo0_o[2: 0] <= data_i[2: 0];
                    end
                    `CP0_REG_ENTRYLO1: begin 
                        entrylo1_o[25: 6] <= data_i[25: 6];
                        entrylo1_o[2: 0] <= data_i[2: 0];
                    end
                    `CP0_REG_BADVADDR: begin 
                        badvaddr_o <= data_i;
                    end
                    `CP0_REG_COUNT: begin
                        count_o <= data_i;
                    end
                    `CP0_REG_ENTRYHI: begin 
                        entryhi_o[31: 13] <= data_i[31: 13];
                        entryhi_o[7: 0] <= data_i[7: 0];
                    end
                    `CP0_REG_COMPARE: begin
                        compare_o <= data_i;
                        timer_int_o <= 1'b0;
                    end
                    `CP0_REG_STATUS:    begin
                        status_o[28] <= data_i[28]; //CU0
                        status_o[22] <= data_i[22]; //BEV
                        status_o[15: 8] <= data_i[15: 8]; //IM
                        status_o[4] <= data_i[4]; //UM, user mode - 0, kenerl mode - 1
                        status_o[2: 0] <= data_i[2: 0]; //ERL, EXL, IE
                    end
                    `CP0_REG_EPC:   begin
                        epc_o <= data_i;
                    end
                    `CP0_REG_CAUSE: begin
                        cause_o[9: 8] <= data_i[9: 8]; // software interrupt
                        cause_o[23] <= data_i[23]; // interrupt vector
                    end             
                    `CP0_REG_EBASE: begin
                        ebase_o[29: 12] <= data_i[29: 12]; //only bits 29..12 is writable 
                    end   
                endcase  //case waddr_i
            end // if

            // deal with exception   
            case (excepttype_i)
                32'h00000001: begin  // interruption 
                    if(is_in_delayslot_i == `InDelaySlot) begin
                         epc_o <= current_inst_addr_i - 4;
                         cause_o[31] <= 1'b1;
                     end 
                     else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                     end
                     status_o[1] <= 1'b1; // stutas.EXL
                     cause_o[6: 2] <= 5'b00000; // cause.ExcCode <= 0(interruption)
                end
                32'h00000008: begin  // syscall
                    if(is_in_delayslot_i == `InDelaySlot) begin
                         epc_o <= current_inst_addr_i - 4;
                         cause_o[31] <= 1'b1;
                     end 
                     else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                     end
                     status_o[1] <= 1'b1; // stutas.EXL
                     cause_o[6: 2] <= 5'b01000; // cause.ExcCode <= 8(syscall)
                end
                32'h0000000a: begin  // invalid instruction
                    if(is_in_delayslot_i == `InDelaySlot) begin
                         epc_o <= current_inst_addr_i - 4;
                         cause_o[31] <= 1'b1;
                     end 
                     else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                     end
                     status_o[1] <= 1'b1; // stutas.EXL
                     cause_o[6: 2] <= 5'b01010; // cause.ExcCode <= 10(RI)
                end
                32'h0000000b: begin  // ADEL
                    if(is_in_delayslot_i == `InDelaySlot) begin
                         epc_o <= current_inst_addr_i - 4;
                         cause_o[31] <= 1'b1;
                     end 
                     else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                     end
                     status_o[1] <= 1'b1; // stutas.EXL
                     cause_o[6: 2] <= 5'b00100; // cause.ExcCode <= 4(ADEL)
                     badvaddr_o <= unaligned_addr_i;
                     
                     $display("badvaddr_o = %h", badvaddr_o);
                end
                32'h0000000c: begin  // ADES
                    if(is_in_delayslot_i == `InDelaySlot) begin
                         epc_o <= current_inst_addr_i - 4;
                         cause_o[31] <= 1'b1;
                     end 
                     else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                     end
                     status_o[1] <= 1'b1; // stutas.EXL
                     cause_o[6: 2] <= 5'b00101; // cause.ExcCode <= 5(ADES)
                     badvaddr_o <= unaligned_addr_i;

                     $display("badvaddr_o = %h", badvaddr_o);
                end
                32'h0000000e: begin  // eret
                     status_o[1] <= 1'b0; // stutas.EXL
                end
                32'h0000000f: begin  // TLBL, inst
                    if(is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                    end 
                    else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                    end
                    status_o[1] <= 1'b1; // stutas.EXL
                    cause_o[6: 2] <= 5'b00010; // cause.ExcCode <= 2(TLBL)
                    badvaddr_o <= badvaddr_i;
                    entryhi_o[31: 13] <= badvaddr_i[31: 13];
                    $display("Exception: Inst TLBL");
                end
                32'h00000010: begin   // TLB mod
                    if(is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                    end 
                    else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                    end
                    status_o[1] <= 1'b1; // stutas.EXL
                    cause_o[6: 2] <= 5'b00001; // cause.ExcCode <= 1(TLB Modify)
                    badvaddr_o <= badvaddr_i;
                    entryhi_o[31: 13] <= badvaddr_i[31: 13];
                    $display("Exception: Data TLB Mod");
                end
                32'h00000011: begin    // TLBL DATA 
                    if(is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                    end 
                    else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                    end
                    status_o[1] <= 1'b1; // stutas.EXL
                    cause_o[6: 2] <= 5'b00010; // cause.ExcCode <= 2(TLBL)
                    badvaddr_o <= badvaddr_i;
                    entryhi_o[31: 13] <= badvaddr_i[31: 13];
                    $display("Exception: Data TLBL, epc = %h, badvaddr = %h"
						  , epc_o, badvaddr_o);
						  
                end
                32'h00000012: begin    // TLBS 
                    if(is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;
                    end 
                    else begin 
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                    end
                    status_o[1] <= 1'b1; // stutas.EXL
                    cause_o[6: 2] <= 5'b00011; // cause.ExcCode <= 3(TLBS)
                    badvaddr_o <= badvaddr_i;
                    entryhi_o[31: 13] <= badvaddr_i[31: 13];
                    $display("Exception: Data TLBS, epc = %h, badvaddr = %h"
                          , epc_o, badvaddr_o);
                end
                default: begin 
                    /**/
                end
            endcase    
            
           
        end // else
    end // always

    always @ (*) begin
        if(rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end 
        else begin
            case (raddr_i) 
                `CP0_REG_INDEX: begin
                    data_o <= {index_o[31], 27'b0, index_o[3: 0]};
                end
                `CP0_REG_ENTRYLO0: begin 
                    data_o <= {2'b0, entrylo0_o[29: 6], 3'b0, entrylo0_o[2: 0]};
                end
                `CP0_REG_ENTRYLO1: begin 
                    data_o <= {2'b0, entrylo1_o[29: 6], 3'b0, entrylo1_o[2: 0]};
                end
                `CP0_REG_BADVADDR: begin 
                    data_o <= badvaddr_o;
                end
                `CP0_REG_COUNT: begin
                    data_o <= count_o;
                end
                `CP0_REG_ENTRYHI: begin 
                    data_o <= {entryhi_o[31: 13], 5'b0, entryhi_o[7: 0]};
                end
                `CP0_REG_COMPARE: begin
                    data_o <= compare_o;    
                end
                `CP0_REG_STATUS: begin
                    data_o <= status_o;
                end
                `CP0_REG_EPC: begin
                    data_o <= epc_o;
                end
                `CP0_REG_CAUSE: begin
                    data_o <= {cause_o[31], 7'b0, cause_o[23],7'b0, int_i, 1'b0, cause_o[6: 2], 2'b00};
                end             
                `CP0_REG_EBASE: begin
                    data_o <= {2'b10, ebase_o[29: 12], 12'b0};        
                end
            endcase  //case addr_i          
        end    //if
    end      //always

endmodule