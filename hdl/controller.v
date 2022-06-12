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

`define IDLE 2'b00
`define BUSY 2'b01
`define DONE 2'b10

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
  wire [`ADDR_WIDTH-1:0] n_row_batches  = (m_i + 'h008 - 'h001) >> 3;  // m / 8
  wire [`ADDR_WIDTH-1:0] n_col_batches  = (n_i + 'h008 - 'h001) >> 3;  // n / 8
  wire [`ADDR_WIDTH-1:0] n_batch_cycles = (k_i < 'h008)? 'h008 : k_i;  // >= 8

  // Counters for batches
  reg [`ADDR_WIDTH-1:0] row_batch_q, row_batch_d;
  reg [`ADDR_WIDTH-1:0] col_batch_q, col_batch_d;
  reg [`ADDR_WIDTH-1:0] batch_cycle_q, batch_cycle_d;

  // Source Addresses
  wire [`ADDR_WIDTH-1:0] batch_base_addra = row_batch_q * k_i + base_addra_i;
  wire [`ADDR_WIDTH-1:0] batch_base_addrb = col_batch_q * k_i + base_addrb_i;
  reg  [`ADDR_WIDTH-1:0] addra_q, addra_d;
  reg  [`ADDR_WIDTH-1:0] addrb_q, addrb_d;

  // Boundary conditions
  wire row_batch_end = row_batch_q == n_row_batches - 'd1;
  wire col_batch_end = col_batch_q == n_col_batches - 'd1;
  wire batch_end     = batch_cycle_q == n_batch_cycles - 'd1;
  wire batch_begin   = ~|batch_cycle_q;  // == 0

  // Assign output signals
  assign valid_o       = state_q[1];               // state_q == 2'b10
  assign batch_end_o   = batch_end;
  assign batch_begin_o = batch_begin;
  assign ensys_o       = state_q[0];               // state_q == 2'b01
  assign bubble_o      = batch_cycle_q > k_i - 1;  // insert bubbles when > k

  // Batch counters
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      batch_cycle_q <= 'd0;
      row_batch_q   <= 'd0;
      col_batch_q   <= 'd0;
    end else begin
      batch_cycle_q <= batch_cycle_d;
      row_batch_q   <= row_batch_d;
      col_batch_q   <= col_batch_d;
    end
  end

  // Row batch counter (slowest)
  always @(*) begin
    if (state_q == `BUSY) begin
      if (row_batch_end && col_batch_end && batch_end) begin
        row_batch_d = 'd0;                // Reset when all end
      end else if (col_batch_end && batch_end) begin
        row_batch_d = row_batch_q + 'd1;  // Increment as col batch ends
      end else begin
        row_batch_d = row_batch_q;        // Remain unchanged
      end
    end else begin
      row_batch_d = 'd0;
    end
  end

  // Column batch counter (medium)
  always @(*) begin
    if (state_q == `BUSY) begin
      if (col_batch_end && batch_end) begin
        col_batch_d = 'd0;                // Reset when column batch ends
      end else if (batch_end) begin
        col_batch_d = col_batch_q + 'd1;  // Increment as batch ends
      end else begin
        col_batch_d = col_batch_q;        // Remain unchanged
      end
    end else begin
      col_batch_d = 'd0;
    end
  end

  // Batch cycle counter (fastest)
  always @(*) begin
    if (state_q == `BUSY &&
        !(row_batch_end && col_batch_end && batch_end)) begin
      if (batch_end) begin
        batch_cycle_d = 'd0;                  // Reset when ends
      end else begin
        batch_cycle_d = batch_cycle_q + 'd1;  // Increment every cycle
      end
    end else begin
      batch_cycle_d = 'd0;
    end
  end

  // Source address generation
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      addra_q <= 'd0;
      addrb_q <= 'd0;
    end else begin
      addra_q <= addra_d;
      addrb_q <= addrb_d;
    end
  end

  always @(*) begin
    if (state_q == `BUSY) begin
      addra_d = batch_base_addra + batch_cycle_d;
      addra_d = batch_base_addra + batch_cycle_d;
    end else begin
      addra_d = 'd0;
      addra_d = 'd0;
    end
  end

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
        if (row_batch_q == n_row_batches && col_batch_q == n_col_batches) begin
          state_d = `DONE;
        end else begin
          state_d = `BUSY;
        end
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
