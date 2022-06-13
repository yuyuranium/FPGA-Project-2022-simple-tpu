//
// top.v
// 
// Top module for simulation. This module simulates memory mapped registers and
// connects all the compononts in the system, including global buffer, together.
// Note that we will package only the tpu into an AXI IP eventually.
//
`include "def.v"

module top (
  input             clk_i,
  input             rst_ni,

  input             we_i,
  input      [2:0]  addr_i,
  input      [31:0] wdata_i,
  output reg [31:0] rdata_o
);

  integer i;
  reg [31:0] slv_reg[8];  // 8 slave registers
  reg [31:0] reg_data;

  wire start = slv_reg[0][0], valid;
  wire [`ADDR_WIDTH-1:0] m          = slv_reg[2][`ADDR_WIDTH-1:0];
  wire [`ADDR_WIDTH-1:0] k          = slv_reg[3][`ADDR_WIDTH-1:0];
  wire [`ADDR_WIDTH-1:0] n          = slv_reg[4][`ADDR_WIDTH-1:0];
  wire [`ADDR_WIDTH-1:0] base_addra = slv_reg[5][`ADDR_WIDTH-1:0];
  wire [`ADDR_WIDTH-1:0] base_addrb = slv_reg[5][`ADDR_WIDTH-1:0];
  wire [`ADDR_WIDTH-1:0] base_addrp = slv_reg[5][`ADDR_WIDTH-1:0];
  wire [`ADDR_WIDTH-1:0] addra, addrb, addrp;
  wire [`WORD_WIDTH-1:0] worda, wordb, wordp;
  wire ena, enb, enp, wea, web, wep;


  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (i = 0; i < 8; i = i + 1) begin
        slv_reg[i] <= 32'd0;
      end
    end else begin
      if (we_i) begin
        slv_reg[addr_i] <= wdata_i;
      end
    end
  end

  always @(posedge clk_i) begin
    rdata_o <= reg_data;
  end

  always @(*) begin
    case (addr_i)
      3'o0: reg_data = slv_reg[0];
      3'o1: reg_data = { 31'd0, valid };
      3'o2: reg_data = slv_reg[2];
      3'o3: reg_data = slv_reg[3];
      3'o4: reg_data = slv_reg[4];
      3'o5: reg_data = slv_reg[5];
      3'o6: reg_data = slv_reg[6];
      3'o7: reg_data = slv_reg[7];
      default: reg_data = 32'd0;
    endcase
  end

  tpu tpu (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),

    .start_i     (start),
    .valid_o     (valid),

    .m_i         (m),
    .k_i         (k),
    .n_i         (n),

    .base_addra_i(base_addra),
    .base_addrb_i(base_addrb),
    .base_addrp_i(base_addrp),

    .ena_o       (ena),
    .wea_o       (wea),
    .addra_o     (addra),
    .worda_i     (worda),

    .enb_o       (enb),
    .web_o       (web),
    .addrb_o     (addrb),
    .wordb_i     (wordb),

    .enp_o       (enp),
    .wep_o       (wep),
    .addrp_o     (addrp),
    .wordp_o     (wordp)
  );

  global_buffer gbuffa (
    .clk_i  (clk_i),
    .we_i   (wea),
    .en_i   (ena),
    .addr_i (addra),
    .wdata_i(0),
    .rdata_o(worda)
  );

  global_buffer gbuffb (
    .clk_i  (clk_i),
    .we_i   (web),
    .en_i   (enb),
    .addr_i (addrb),
    .wdata_i(0),
    .rdata_o(wordb)
  );

  global_buffer gbuffp (
    .clk_i  (clk_i),
    .we_i   (wep),
    .en_i   (enp),
    .addr_i (addrp),
    .wdata_i(wordp),
    .rdata_o()
  );

endmodule
