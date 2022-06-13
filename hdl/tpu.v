`ifndef _TPU_V
`define _TPU_V

`include "def.v"

module tpu (
  input  clk_i,
  input  rst_ni,

  input  start_i,
  output valid_o,

  // Matrics dimension
  input  [`ADDR_WIDTH-1:0] m_i,
  input  [`ADDR_WIDTH-1:0] k_i,
  input  [`ADDR_WIDTH-1:0] n_i,

  // Base addresses
  input  [`ADDR_WIDTH-1:0] base_addra_i,
  input  [`ADDR_WIDTH-1:0] base_addrb_i,
  input  [`ADDR_WIDTH-1:0] base_addrp_i,

  // Global buffer A interface
  output                   ena_o,
  output                   wea_o,
  output [`ADDR_WIDTH-1:0] addra_o,
  input  [`WORD_WIDTH-1:0] worda_i,

  // Global buffer B interface
  output                   enb_o,
  output                   web_o,
  output [`ADDR_WIDTH-1:0] addrb_o,
  input  [`WORD_WIDTH-1:0] wordb_i,

  // Global buffer P interface
  output                       enp_o,
  output                       wep_o,
  output     [`ADDR_WIDTH-1:0] addrp_o,
  output reg [`WORD_WIDTH-1:0] wordp_o
);

  // Internal controller control signals
  wire       pe_clr, pe_we, ensys, bubble;
  wire [2:0] wordp_sel;
  wire [7:0] datap_we;

  // Wires connecting each pe array
  wire pe_clr_q1, pe_clr_q2, pe_clr_q3, pe_clr_q4,
       pe_clr_q5, pe_clr_q6, pe_clr_q7;

  wire pe_we_q1, pe_we_q2, pe_we_q3, pe_we_q4,
       pe_we_q5, pe_we_q6, pe_we_q7;

  wire [`WORD_WIDTH-1:0] srca_word_q1, srca_word_q2, srca_word_q3, srca_word_q4,
                         srca_word_q5, srca_word_q6, srca_word_q7;

  wire [`WORD_WIDTH-1:0] wordp0, wordp1, wordp2, wordp3,
                         wordp4, wordp5, wordp6, wordp7;

  // Assign output signals
  reg [`WORD_WIDTH-1:0] wordp;

  always @(*) begin
    if (wep_o) begin
      case (wordp_sel)
        3'o0: wordp = wordp0;
        3'o1: wordp = wordp1;
        3'o2: wordp = wordp2;
        3'o3: wordp = wordp3;
        3'o4: wordp = wordp4;
        3'o5: wordp = wordp5;
        3'o6: wordp = wordp6;
        3'o7: wordp = wordp7;
      endcase
    end else begin
      wordp = 'd0;
    end
  end

  always @(*) begin
    if (wep_o) begin
      wordp_o[`DATA0] = datap_we[0] ? wordp[`DATA0] : 'd0;
      wordp_o[`DATA1] = datap_we[1] ? wordp[`DATA1] : 'd0;
      wordp_o[`DATA2] = datap_we[2] ? wordp[`DATA2] : 'd0;
      wordp_o[`DATA3] = datap_we[3] ? wordp[`DATA3] : 'd0;
      wordp_o[`DATA4] = datap_we[4] ? wordp[`DATA4] : 'd0;
      wordp_o[`DATA5] = datap_we[5] ? wordp[`DATA5] : 'd0;
      wordp_o[`DATA6] = datap_we[6] ? wordp[`DATA6] : 'd0;
      wordp_o[`DATA7] = datap_we[7] ? wordp[`DATA7] : 'd0;
    end else begin
      wordp_o = 'd0;
    end
  end

  // Source operands
  wire [`WORD_WIDTH-1:0] srca_word, srcb_word;

  controller controller (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),

    .start_i     (start_i),
    .valid_o     (valid_o),

    .m_i         (m_i),
    .k_i         (k_i),
    .n_i         (n_i),

    .base_addra_i(base_addra_i),
    .base_addrb_i(base_addrb_i),
    .base_addrp_i(base_addrp_i),

    .pe_clr_o    (pe_clr),
    .pe_we_o     (pe_we),

    .ensys_o     (ensys),
    .bubble_o    (bubble),

    .ena_o       (ena_o),
    .wea_o       (wea_o),
    .addra_o     (addra_o),

    .enb_o       (enb_o),
    .web_o       (web_o),
    .addrb_o     (addrb_o),

    .enp_o       (enp_o),
    .wep_o       (wep_o),
    .addrp_o     (addrp_o),

    .wordp_sel_o (wordp_sel),
    .datap_we_o  (datap_we)
  );

  systolic_input_setup srca_setup (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .en_i  (ensys),
    .word_i(bubble ? 'd0 : worda_i),
    .skew_o(srca_word)
  );

  systolic_input_setup srcb_setup (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .en_i  (ensys),
    .word_i(bubble ? 'd0 : wordb_i),
    .skew_o(srcb_word)
  );

  pe_array col0 (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (pe_clr),
    .clr_o      (pe_clr_q1),
    .we_i       (pe_we),
    .we_o       (pe_we_q1),
    .srca_word_i(srca_word),
    .srca_word_o(srca_word_q1),
    .srcb_i     (srcb_word[`DATA0]),
    .wordp_o    (wordp0)
  );

  pe_array col1 (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (pe_clr_q1),
    .clr_o      (pe_clr_q2),
    .we_i       (pe_we_q1),
    .we_o       (pe_we_q2),
    .srca_word_i(srca_word_q1),
    .srca_word_o(srca_word_q2),
    .srcb_i     (srcb_word[`DATA1]),
    .wordp_o    (wordp1)
  );

  pe_array col2 (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (pe_clr_q2),
    .clr_o      (pe_clr_q3),
    .we_i       (pe_we_q2),
    .we_o       (pe_we_q3),
    .srca_word_i(srca_word_q2),
    .srca_word_o(srca_word_q3),
    .srcb_i     (srcb_word[`DATA2]),
    .wordp_o    (wordp2)
  );

  pe_array col3 (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (pe_clr_q3),
    .clr_o      (pe_clr_q4),
    .we_i       (pe_we_q3),
    .we_o       (pe_we_q4),
    .srca_word_i(srca_word_q3),
    .srca_word_o(srca_word_q4),
    .srcb_i     (srcb_word[`DATA3]),
    .wordp_o    (wordp3)
  );

  pe_array col4 (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (pe_clr_q4),
    .clr_o      (pe_clr_q5),
    .we_i       (pe_we_q4),
    .we_o       (pe_we_q5),
    .srca_word_i(srca_word_q4),
    .srca_word_o(srca_word_q5),
    .srcb_i     (srcb_word[`DATA4]),
    .wordp_o    (wordp4)
  );

  pe_array col5 (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (pe_clr_q5),
    .clr_o      (pe_clr_q6),
    .we_i       (pe_we_q5),
    .we_o       (pe_we_q6),
    .srca_word_i(srca_word_q5),
    .srca_word_o(srca_word_q6),
    .srcb_i     (srcb_word[`DATA5]),
    .wordp_o    (wordp5)
  );

  pe_array col6 (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (pe_clr_q6),
    .clr_o      (pe_clr_q7),
    .we_i       (pe_we_q6),
    .we_o       (pe_we_q7),
    .srca_word_i(srca_word_q6),
    .srca_word_o(srca_word_q7),
    .srcb_i     (srcb_word[`DATA6]),
    .wordp_o    (wordp6)
  );

  pe_array col7 (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .clr_i      (pe_clr_q7),
    .clr_o      (),
    .we_i       (pe_we_q7),
    .we_o       (),
    .srca_word_i(srca_word_q7),
    .srca_word_o(),
    .srcb_i     (srcb_word[`DATA7]),
    .wordp_o    (wordp7)
  );

endmodule

`endif
