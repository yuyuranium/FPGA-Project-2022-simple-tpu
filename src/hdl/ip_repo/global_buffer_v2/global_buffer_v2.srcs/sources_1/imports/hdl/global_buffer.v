//
// global_buffer.v
//
// This is to simulate the behavior of either input sram, weight sram, or output
// sram. For final design, this may need to be changed into a dual port memory
// that is capable of being read or written by the PS. As for simulation, the
// value in the buffer is loaded by the testbench and only one port is needed.
// 
// Using "True-Dual-Port Block RAM Write-First Mode" template by Xilinx
//
`ifndef _GLOBAL_BUFFER_V
`define _GLOBAL_BUFFER_V

`include "def.v"

module global_buffer (

  // A port for PS
  input clk_a_i,
  input we_a_i,  // Write enable A
  input en_a_i,  // Enable A
  input      [`ADDR_WIDTH+2-1:0] addr_a_i,
  input      [`WORD_WIDTH/4-1:0] wdata_a_i,
  output reg [`WORD_WIDTH/4-1:0] rdata_a_o,

  // B port for TPU
  input clk_b_i,
  input we_b_i,  // Write enable B
  input en_b_i,  // Enable B
  input      [`ADDR_WIDTH-1:0] addr_b_i,
  input      [`WORD_WIDTH-1:0] wdata_b_i,
  output reg [`WORD_WIDTH-1:0] rdata_b_o
);

  // Global buffer
  reg [`WORD_WIDTH-1:0] gbuff [`GBUFF_ADDR_BEGIN:`GBUFF_ADDR_END];

  // Global buffer read/write behavior
  wire [`ADDR_WIDTH-1:0] addr_a_base   = addr_a_i[`ADDR_WIDTH+2-1:2];
  wire [1:0]             addr_a_offset = addr_a_i[1:0];
  
  // A port
  always @(posedge clk_a_i) begin
    if (en_a_i) begin
      if (we_a_i) begin
        case (addr_a_offset)
          2'b00:
            gbuff[addr_a_base][31:0]   <= wdata_a_i;
          2'b01:
            gbuff[addr_a_base][63:32]  <= wdata_a_i;
          2'b10:
            gbuff[addr_a_base][95:64]  <= wdata_a_i;
          2'b11:
            gbuff[addr_a_base][127:96] <= wdata_a_i;
        endcase
        rdata_a_o <= wdata_a_i;
      end else begin
        case (addr_a_offset)
          2'b00:
            rdata_a_o <= gbuff[addr_a_base][31:0];
          2'b01:
            rdata_a_o <= gbuff[addr_a_base][63:32];
          2'b10:
            rdata_a_o <= gbuff[addr_a_base][95:64];
          2'b11:
            rdata_a_o <= gbuff[addr_a_base][127:96];
        endcase
      end
    end
  end

  // B port
  always @(posedge clk_b_i) begin
    if (en_b_i) begin
      if (we_b_i) begin
        gbuff[addr_b_i] <= wdata_b_i;
        rdata_b_o       <= wdata_b_i;
      end else begin
        rdata_b_o <= gbuff[addr_b_i];
      end
    end
  end

endmodule

`endif
