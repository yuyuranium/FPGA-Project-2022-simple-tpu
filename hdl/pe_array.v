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

  // Control signals from controller
  input  clr_i,
  output clr_o,
  input  we_i,
  output we_o,

  // A (word)
  input  [`WORD_WIDTH-1:0] srca_word_i,
  output [`WORD_WIDTH-1:0] srca_word_o,

  // B (data)
  input  [`DATA_WIDTH-1:0] srcb_i,

  // Output word
  output [`WORD_WIDTH-1:0] wordp_o
);

  // Wires connecting each pe
  wire clr_q1, clr_q2, clr_q3, clr_q4, clr_q5, clr_q6, clr_q7;

  wire [`DATA_WIDTH-1:0] srcb_q1, srcb_q2, srcb_q3, srcb_q4,
                         srcb_q5, srcb_q6, srcb_q7;

  // Output word register
  reg  [`WORD_WIDTH-1:0] wordp_q;
  wire [`WORD_WIDTH-1:0] wordp_d;

  // Write enable shift registers
  reg  [8+`OUTPUT_LAT-1:0] we_q;
  wire [8+`OUTPUT_LAT-1:0] we_d = { we_q[8+`OUTPUT_LAT-2:0], we_i };  // << 1

  // Assign output signals
  assign clr_o   = clr_q1;   // 1 cycle delay
  assign we_o    = we_q[1];  // 1 cycle delay
  assign wordp_o = wordp_q;  // 1 cycle delay

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      we_q <= 'd0;
    end else begin
      we_q <= we_d;
    end
  end

  // Output word control
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wordp_q <= 'd0;
    end else begin
      if (we_q[`OUTPUT_LAT])   wordp_q[`DATA0] <= wordp_d[`DATA0];
      if (we_q[`OUTPUT_LAT+1]) wordp_q[`DATA1] <= wordp_d[`DATA1];
      if (we_q[`OUTPUT_LAT+2]) wordp_q[`DATA2] <= wordp_d[`DATA2];
      if (we_q[`OUTPUT_LAT+3]) wordp_q[`DATA3] <= wordp_d[`DATA3];
      if (we_q[`OUTPUT_LAT+4]) wordp_q[`DATA4] <= wordp_d[`DATA4];
      if (we_q[`OUTPUT_LAT+5]) wordp_q[`DATA5] <= wordp_d[`DATA5];
      if (we_q[`OUTPUT_LAT+6]) wordp_q[`DATA6] <= wordp_d[`DATA6];
      if (we_q[`OUTPUT_LAT+7]) wordp_q[`DATA7] <= wordp_d[`DATA7];
    end
  end

  pe pe0 (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .clr_i (clr_i),
    .clr_o (clr_q1),
    .srca_i(srca_word_i[`DATA0]),
    .srca_o(srca_word_o[`DATA0]),
    .srcb_i(srcb_i),
    .srcb_o(srcb_q1),
    .psum_o(wordp_d[`DATA0])
  );

  pe pe1 (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .clr_i (clr_q1),
    .clr_o (clr_q2),
    .srca_i(srca_word_i[`DATA1]),
    .srca_o(srca_word_o[`DATA1]),
    .srcb_i(srcb_q1),
    .srcb_o(srcb_q2),
    .psum_o(wordp_d[`DATA1])
  );

  pe pe2 (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .clr_i (clr_q2),
    .clr_o (clr_q3),
    .srca_i(srca_word_i[`DATA2]),
    .srca_o(srca_word_o[`DATA2]),
    .srcb_i(srcb_q2),
    .srcb_o(srcb_q3),
    .psum_o(wordp_d[`DATA2])
  );

  pe pe3 (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .clr_i (clr_q3),
    .clr_o (clr_q4),
    .srca_i(srca_word_i[`DATA3]),
    .srca_o(srca_word_o[`DATA3]),
    .srcb_i(srcb_q3),
    .srcb_o(srcb_q4),
    .psum_o(wordp_d[`DATA3])
  );

  pe pe4 (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .clr_i (clr_q4),
    .clr_o (clr_q5),
    .srca_i(srca_word_i[`DATA4]),
    .srca_o(srca_word_o[`DATA4]),
    .srcb_i(srcb_q4),
    .srcb_o(srcb_q5),
    .psum_o(wordp_d[`DATA4])
  );

  pe pe5 (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .clr_i (clr_q5),
    .clr_o (clr_q6),
    .srca_i(srca_word_i[`DATA5]),
    .srca_o(srca_word_o[`DATA5]),
    .srcb_i(srcb_q5),
    .srcb_o(srcb_q6),
    .psum_o(wordp_d[`DATA5])
  );

  pe pe6 (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .clr_i (clr_q6),
    .clr_o (clr_q7),
    .srca_i(srca_word_i[`DATA6]),
    .srca_o(srca_word_o[`DATA6]),
    .srcb_i(srcb_q6),
    .srcb_o(srcb_q7),
    .psum_o(wordp_d[`DATA6])
  );

  pe pe7 (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .clr_i (clr_q7),
    .clr_o (),
    .srca_i(srca_word_i[`DATA7]),
    .srca_o(srca_word_o[`DATA7]),
    .srcb_i(srcb_q7),
    .srcb_o(),
    .psum_o(wordp_d[`DATA7])
  );

endmodule

`endif
