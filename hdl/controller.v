//
// controller.v
//
// State machine based controller for the mm accelerator. The controller accepts
// the dimension of matrics, base addresses of where to read or where to write,
// and the start signal and then generates control signals for all components.
//
`ifndef _CONTROLLER_V
`define _CONTROLLER_V

`include "def.v"

`define IDLE 0
`define BUSY 1
`define DONE 2

module controller (
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

  // Batch
  output batch_begin_o,
  output batch_end_o,

  // Systolic input setup interface
  output ensys_o,
  output bubble_o,

  // Global buffer A interface
  output                   ena_o,
  output                   wea_o,
  output [`ADDR_WIDTH-1:0] addra_o,

  // Global buffer B interface
  output                   enb_o,
  output                   web_o,
  output [`ADDR_WIDTH-1:0] addrb_o,

  // Global buffer P interface
  output                   enp_o,
  output                   wep_o,
  output [`ADDR_WIDTH-1:0] addrp_o
);

  // Main state
  reg [1:0] state_q, state_d;

  // Boundaries for batches (constant)
  wire [`ADDR_WIDTH-1:0] n_row_batches  = (m_i + 'h008 + 'h001) >> 3;
  wire [`ADDR_WIDTH-1:0] n_col_batches  = (n_i + 'h008 + 'h001) >> 3;
  wire [`ADDR_WIDTH-1:0] n_batch_cycles = (k_i < 'h008)? 'h008 : k_i;

  // Counters for batches
  reg [`ADDR_WIDTH-1:0] row_batch_q, row_batch_d;
  reg [`ADDR_WIDTH-1:0] col_batch_q, col_batch_d;

  // Address offsets to each global buffer
  reg [`ADDR_WIDTH-1:0] offseta, offsetb, offsetp;

  // Main state machine behavior
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= 'd0;
    end else begin
      state_q <= state_d;
    end
  end

  always @(*) begin
    case (state_q)
      `IDLE: begin
        state_d = (start_i)? `BUSY : `IDLE;
      end
      `BUSY: begin
        state_d = (start_i)? `DONE : `BUSY;
      end
      `DONE: begin
        state_d = (!start_i)? `IDLE : `DONE;
      end
      default: begin
        state_d = `IDLE;
      end
    endcase
  end

endmodule

`endif
