`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2022 11:05:01 PM
// Design Name: 
// Module Name: spi_master_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_master_test(

input reset_n,
input clk,
input btn,
output [3:0] sel,
output [7:0] sseg
);
parameter SPI_MODE=3;
parameter CLKS_PER_HALF_BIT=2;
wire btn_reg;
wire [7:0] master_rx_byte;
db_fsm db_fsm_inst
(
	.clk(clk),
	.reset_n(reset_n),
	.sw(!btn),
	.db_tick(btn_reg)
);

 // Instantiate UUT
  spi_master 
  #(.SPI_MODE(SPI_MODE),
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)) SPI_Master_UUT
  (
   // Control/Data Signals,
   .reset_n(reset_n),     // FPGA Reset
   .clk(clk),         // FPGA Clock
   
   // TX (MOSI) Signals
   .i_tx_byte(master_rx_byte+1),     // Byte to transmit on MOSI
   .i_tx_dv(btn_reg),         // Data Valid Pulse with i_TX_Byte
   .o_tx_ready(master_tx_ready),   // Transmit Ready for Byte
   
   // RX (MISO) Signals
   .o_rx_dv(master_rx_dv),       // Data Valid pulse (1 clock cycle)
   .o_rx_byte(master_rx_byte),   // Byte received on MISO

   // SPI Interface
   .o_spi_clk(spi_clk),
   .i_spi_miso(spi_mosi),
   .o_spi_mosi(spi_mosi)
);

disp_hex_mux disp_unit
(.clk(clk), .reset_n(reset_n),
     .in_3(0), .in_2(0), .in_1({2'b0,master_rx_byte[7:4]}), .in_0({2'b0,master_rx_byte[3:0]}),
     .sel(sel), .sseg(sseg));

endmodule