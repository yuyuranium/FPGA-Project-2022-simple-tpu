//
// pe_array.v
//
// 8 pe's in vertiacl are grouped into a pe array. The pe array recieves the 
// clear signal from controller and then stores the psum output from pe's.
// All the psum output from pe's are assembled into a output word of 128 bits,
// which is to write to the output global buffer.
//
`ifndef _PE_ARRAY_V
`define _PE_ARRAY_V

`include "def.v"

module pe_array(
  input  clk_i,
  input  rst_ni,
  input  clear_i,

  // A (word)
  input  [`WORD_WIDTH-1:0] srca_word_i,
  output [`WORD_WIDTH-1:0] srca_word_o,

  // B (data)
  input  [`DATA_WIDTH-1:0] srcb_i,
  output [`DATA_WIDTH-1:0] srcb_o,

  // Output word
  output [`WORD_WIDTH-1:0] word_o
);

  wire clear_q1, clear_q2, clear_q3, clear_q4,
       clear_q5, clear_q6, clear_q7, clear_q8;
  wire en0 = clear_q1, en1 = clear_q2, en2 = clear_q3, en3 = clear_q4,
       en4 = clear_q5, en5 = clear_q6, en6 = clear_q7, en7 = clear_q8;
  wire [`DATA_WIDTH-1:0] srcb_q1, srcb_q2, srcb_q3, srcb_q4,
                         srcb_q5, srcb_q6, srcb_q7, srcb_q8;
  wire [`WORD_WIDTH-1:0] word_d;
  reg  [`WORD_WIDTH-1:0] word_q;

  // Assign output word and srcb data
  assign word_o = word_q;
  assign srcb_o = srcb_q8;

  // Write enable shift registers
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      word_q <= 'd0;
    end else begin
      if (en0) word_q[`DATA0] <= word_d[`DATA0];
      if (en1) word_q[`DATA1] <= word_d[`DATA1];
      if (en2) word_q[`DATA2] <= word_d[`DATA2];
      if (en3) word_q[`DATA3] <= word_d[`DATA3];
      if (en4) word_q[`DATA4] <= word_d[`DATA4];
      if (en5) word_q[`DATA5] <= word_d[`DATA5];
      if (en6) word_q[`DATA6] <= word_d[`DATA6];
      if (en7) word_q[`DATA7] <= word_d[`DATA7];
    end
  end

  pe pe0 (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clear_i(clear_i),
    .clear_o(clear_q1),
    .srca_i (srca_word_i[`DATA0]),
    .srca_o (srca_word_o[`DATA0]),
    .srcb_i (srcb_i),
    .srcb_o (srcb_q1),
    .psum_o (word_d[`DATA0])
  );

  pe pe1 (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clear_i(clear_q1),
    .clear_o(clear_q2),
    .srca_i (srca_word_i[`DATA1]),
    .srca_o (srca_word_o[`DATA1]),
    .srcb_i (srcb_q1),
    .srcb_o (srcb_q2),
    .psum_o (word_d[`DATA1])
  );

  pe pe2 (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clear_i(clear_q2),
    .clear_o(clear_q3),
    .srca_i (srca_word_i[`DATA2]),
    .srca_o (srca_word_o[`DATA2]),
    .srcb_i (srcb_q2),
    .srcb_o (srcb_q3),
    .psum_o (word_d[`DATA2])
  );

  pe pe3 (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clear_i(clear_q3),
    .clear_o(clear_q4),
    .srca_i (srca_word_i[`DATA3]),
    .srca_o (srca_word_o[`DATA3]),
    .srcb_i (srcb_q3),
    .srcb_o (srcb_q4),
    .psum_o (word_d[`DATA3])
  );

  pe pe4 (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clear_i(clear_q4),
    .clear_o(clear_q5),
    .srca_i (srca_word_i[`DATA4]),
    .srca_o (srca_word_o[`DATA4]),
    .srcb_i (srcb_q4),
    .srcb_o (srcb_q5),
    .psum_o (word_d[`DATA4])
  );

  pe pe5 (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clear_i(clear_q5),
    .clear_o(clear_q6),
    .srca_i (srca_word_i[`DATA5]),
    .srca_o (srca_word_o[`DATA5]),
    .srcb_i (srcb_q5),
    .srcb_o (srcb_q6),
    .psum_o (word_d[`DATA5])
  );

  pe pe6 (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clear_i(clear_q6),
    .clear_o(clear_q7),
    .srca_i (srca_word_i[`DATA6]),
    .srca_o (srca_word_o[`DATA6]),
    .srcb_i (srcb_q6),
    .srcb_o (srcb_q7),
    .psum_o (word_d[`DATA6])
  );

  pe pe7 (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clear_i(clear_q7),
    .clear_o(clear_q8),
    .srca_i (srca_word_i[`DATA7]),
    .srca_o (srca_word_o[`DATA7]),
    .srcb_i (srcb_q7),
    .srcb_o (srcb_q8),
    .psum_o (word_d[`DATA7])
  );

endmodule

`endif
