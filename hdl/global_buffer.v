//
// global_buffer.v
//
// This is to simulate the behavior of either input sram, weight sram, or output
// sram. For final design, this may need to be changed into a dual port memory
// that is capable of being read or written by the PS. As for simulation, the
// value in the buffer is loaded by the testbench and only one port is needed.
//
`ifndef _GLOBAL_BUFFER_V
`define _GLOBAL_BUFFER_V

`include "def.v"

module global_buffer (
  input clk_i,
  input rst_ni,
  input wr_en_i,  // Write enable: 1 to write; 0 to read

  input      [`ADDR_WIDTH-1:0] addr_i,
  input      [`WORD_WIDTH-1:0] rdata_i,
  output reg [`WORD_WIDTH-1:0] wdata_o
);

  // Global buffer
  reg [`WORD_WIDTH-1:0] gbuff [`GBUFF_ADDR_BEGIN:`GBUFF_ADDR_END];

  // Global buffer read/write behavior
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wdata_o <= `WORD_WIDTH'd0;
    end else begin
      if (wr_en_i) begin
        gbuff[addr_i] <= rdata_i;
      end else begin
        wdata_o <= gbuff[addr_i];
      end
    end
  end

endmodule

`endif
