//
// pe.v
//
// The process element doing mac operations and propagating the input a and b to
// its adjacent pe's. The mac operation assumes 16 fixed-point data input with
// 8 fraction bits. The computation is done in 16-32-16 manner to ensure better
// precision. The propagation delay from src to psum is 2 cc's.
//
`ifndef _PE_V
`define _PE_V

`include "def.v"

module pe (
  input  clk_i,
  input  rst_ni,
  input  clear_i,  // Clear signal for accumulated value
  output clear_o,  // Propagation of the clear signal

  input  signed [`DATA_WIDTH-1:0] srca_i,
  input  signed [`DATA_WIDTH-1:0] srcb_i,

  output signed [`DATA_WIDTH-1:0] srca_o,
  output signed [`DATA_WIDTH-1:0] srcb_o,
  output signed [`DATA_WIDTH-1:0] psum_o
);

  // Pipeline registers
  reg                     clear_q;
  reg [`DATA_WIDTH-1:0]   srca_q, srcb_q;
  reg [`DATA_WIDTH*2-1:0] ab_q;
  reg [`DATA_WIDTH*2-1:0] psum_q;

  // Input of pipeline registers
  wire                     clear_d = clear_i;
  wire [`DATA_WIDTH-1:0]   srca_d  = srca_i;
  wire [`DATA_WIDTH-1:0]   srcb_d  = srcb_i;
  wire [`DATA_WIDTH*2-1:0] ab_d    = srca_i * srcb_i;
  wire [`DATA_WIDTH*2-1:0] psum_d  = ab_q + psum_q;


  // Assign ouput signals
  assign clear_o = clear_q;
  assign srca_o  = srca_q;
  assign srcb_o  = srcb_q;
  assign psum_o  = psum_q[23:8];  // Fraction bits are psum_q[15:0]

  // Pipeline propagation of srca and srcb
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      srca_q <= `DATA_WIDTH'd0;
      srcb_q <= `DATA_WIDTH'd0;
    end else begin
      srca_q <= srca_d;
      srcb_q <= srcb_d;
    end
  end

  // Pipeline propagation of clear signal
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_q <= 1'b0;
    end else begin
      clear_q <= clear_d;
    end
  end

  // Pipeline propagation of ab and psum
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ab_q   <= 'd0;
      psum_q <= 'd0;
    end else begin
      ab_q   <= ab_d;
      psum_q <= psum_d;
    end
  end

endmodule

`endif
