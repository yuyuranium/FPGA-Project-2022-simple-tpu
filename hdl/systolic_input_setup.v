//
// systolic_input_setup.v
// 
// Using shift registers to skew the word so that the timing is correct for
// futhur computation.
//
//  buf_q
//  |  buf_q2
//  |  |  buf_q3
//  |  |  |  buf_q4
//  |  |  |  |  buf_q5
//  |  |  |  |  |  buf_q6
//  |  |  |  |  |  |  buf_q7
//  |  |  |  |  |  |  |
//
`ifndef _SYSTOLIC_INPUT_SETUP_V
`define _SYSTOLIC_INPUT_SETUP_V

`include "def.v"

module systolic_input_setup (
  input  clk_i,
  input  rst_ni,
  input  en_i,  // Enable

  input  [`WORD_WIDTH-1:0] word_i,
  output [`WORD_WIDTH-1:0] skew_o
);

  reg [`DATA_WIDTH*7-1:0] buf_q1;  // 1-cycle delay
  reg [`DATA_WIDTH*6-1:0] buf_q2;  // 2-cycle delay
  reg [`DATA_WIDTH*5-1:0] buf_q3;  // 3-cycle delay
  reg [`DATA_WIDTH*4-1:0] buf_q4;  // 4-cycle delay
  reg [`DATA_WIDTH*3-1:0] buf_q5;  // 5-cycle delay
  reg [`DATA_WIDTH*2-1:0] buf_q6;  // 6-cycle delay
  reg [`DATA_WIDTH-1:0]   buf_q7;  // 7-cycle delay

  assign skew_o = {
    word_i[`DATA7], buf_q1[`DATA6], buf_q2[`DATA5], buf_q3[`DATA4],
    buf_q4[`DATA3], buf_q5[`DATA2], buf_q6[`DATA1], buf_q7[`DATA0]
  };

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      buf_q1 <= 'd0;
      buf_q2 <= 'd0;
      buf_q3 <= 'd0;
      buf_q4 <= 'd0;
      buf_q5 <= 'd0;
      buf_q6 <= 'd0;
      buf_q7 <= 'd0;
    end else begin
      if (en_i) begin
        buf_q1 <= word_i[`DATA_WIDTH*7-1:0];
        buf_q2 <= buf_q1[`DATA_WIDTH*6-1:0];
        buf_q3 <= buf_q2[`DATA_WIDTH*5-1:0];
        buf_q4 <= buf_q3[`DATA_WIDTH*4-1:0];
        buf_q5 <= buf_q4[`DATA_WIDTH*3-1:0];
        buf_q6 <= buf_q5[`DATA_WIDTH*2-1:0];
        buf_q7 <= buf_q6[`DATA_WIDTH-1:0];
      end
    end
  end

endmodule

`endif
