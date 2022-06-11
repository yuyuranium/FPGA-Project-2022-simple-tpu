//
// global_buffer.v
//
// This is to simulate the behavior of either input sram, weight sram, or output
// sram. For final design, this may need to be changed into a dual port memory
// that is capable of being read or written by the PS. As for simulation, the
// value in the buffer is loaded by the testbench and only one port is needed.
// 
// Using "Single-Port Block RAM Write-First Mode" template by Xilinx
//
`ifndef _GLOBAL_BUFFER_V
`define _GLOBAL_BUFFER_V

`include "def.v"

module global_buffer (
  input clk_i,
  input we_i,  // Write enable
  input en_i,  // Enable

  input      [`ADDR_WIDTH-1:0] addr_i,
  input      [`WORD_WIDTH-1:0] rdata_i,
  output reg [`WORD_WIDTH-1:0] wdata_o
);

  // Global buffer
  reg [`WORD_WIDTH-1:0] gbuff [`GBUFF_ADDR_BEGIN:`GBUFF_ADDR_END];

  // Global buffer read/write behavior
  always @(posedge clk_i) begin
    if (en_i) begin
      if (we_i) begin
        gbuff[addr_i] <= rdata_i;
        wdata_o       <= rdata_i;
      end else begin
        wdata_o <= gbuff[addr_i];
      end
    end
  end

endmodule

`endif
