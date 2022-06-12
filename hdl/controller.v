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
`define WAIT 2'b11

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

  // PE control signals
  output pe_clear,
  output pe_we,

  // Systolic input setup interface
  output ensys_o,
  output bubble_o,

  // Global buffer A interface
  output                       ena_o,
  output                       wea_o,
  output     [`ADDR_WIDTH-1:0] addra_o,

  // Global buffer B interface
  output                       enb_o,
  output                       web_o,
  output     [`ADDR_WIDTH-1:0] addrb_o,

  // Global buffer P interface
  output                       enp_o,
  output                       wep_o,
  output     [`ADDR_WIDTH-1:0] addrp_o,

  output reg [7:0]             data_en_o
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

  // Global buffer read/write enable
  wire rd_en = (state_q == `BUSY) &&
    !(row_batch_end && col_batch_end && batch_end);  // Busy and not done yet
  wire wr_en = (wr_state_q == `BUSY);

  // Source Addresses
  wire [`ADDR_WIDTH-1:0] batch_base_addra = row_batch_q * k_i + base_addra_i;
  wire [`ADDR_WIDTH-1:0] batch_base_addrb = col_batch_q * k_i + base_addrb_i;
  reg  [`ADDR_WIDTH-1:0] addra_q, addra_d;
  reg  [`ADDR_WIDTH-1:0] addrb_q, addrb_d;

  // Target Address
  wire [3:0]             row_lat = `OUTPUT_LAT + batch_m - 4'h1;  // Row latency
  wire [3:0]             col_lat = batch_n - 4'h1;  // Column latency
  reg  [1:0]             wr_state_q, wr_state_d;    // Write state
  reg  [3:0]             lat_cnt_q, lat_cnt_d;      // Latency counter
  reg  [`ADDR_WIDTH-1:0] addrp_q, addrp_d;

  // Boundary conditions
  wire row_batch_end = row_batch_q == n_row_batches - 'd1;
  wire col_batch_end = col_batch_q == n_col_batches - 'd1;
  wire batch_end     = batch_cycle_q == n_batch_cycles - 'd1;

  wire [3:0] rem_m   = m_i[3:0] & 4'b0111;       // m % 8
  wire [3:0] rem_n   = n_i[3:0] & 4'b0111;       // n % 8
  wire [3:0] batch_m = (!row_batch_end)? 4'h8 :
                       (~|rem_m)? 4'h8 : rem_m;  // if rem_m == 0 then 8
  wire [3:0] batch_n = (!col_batch_end)? 4'h8 :
                       (~|rem_n)? 4'h8 : rem_n;  // if rem_n == 0 then 8

  // Assign output signals
  assign valid_o  = state_q == `DONE;
  assign pe_we    = batch_cycle_q == (k_i - 'd1);  // Last data is sent
  assign pe_clear = ~|batch_cycle_q;               // New batch data is sent
  assign ensys_o  = rd_en;
  assign bubble_o = batch_cycle_q > (k_i - 1);     // Insert bubbles when > k

  // Global buffer interfaces
  assign ena_o   = rd_en;    // Enable when read enable
  assign wea_o   = 1'b0;     // Always read
  assign addra_o = addra_q;

  assign enb_o   = rd_en;    // Enable when read enable
  assign web_o   = 1'b0;     // Always read
  assign addrb_o = addrb_q;

  assign enp_o   = wr_en;    // Enable when write enable
  assign wep_o   = wr_en;    // Write enable when write enable
  assign addrp_o = addrp_q;

  always @(*) begin
    case (batch_m)
      4'h1:
        data_en_o = 8'b00000001;
      4'h2:
        data_en_o = 8'b00000011;
      4'h3:
        data_en_o = 8'b00000111;
      4'h4:
        data_en_o = 8'b00001111;
      4'h5:
        data_en_o = 8'b00011111;
      4'h6:
        data_en_o = 8'b00111111;
      4'h7:
        data_en_o = 8'b01111111;
      4'h8:
        data_en_o = 8'b11111111;
      default:
        data_en_o = 8'b00000000;
    endcase
  end

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
    if (rd_en) begin                          // when read enable
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
    if (rd_en) begin
      addra_d = batch_base_addra + batch_cycle_d;
      addrb_d = batch_base_addrb + batch_cycle_d;
    end else begin
      addra_d = 'd0;
      addrb_d = 'd0;
    end
  end

  // Target address generation
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      addrp_q <= base_addrp_i;
    end else begin
      addrp_q <= addrp_d;
    end
  end

  always @(*) begin
    if (wr_en) begin
      addrp_d = addrp_q + 'd1;
    end
      addrp_d = addrp_q;
  end

  // Target address generator state machine behavior
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_state_q <= `IDLE;
      lat_cnt_q  <= 'd0;
    end else begin
      wr_state_q <= wr_state_d;
      lat_cnt_q  <= lat_cnt_d;
    end
  end

  always @(*) begin
    if (state_q == `BUSY) begin
      case (wr_state_q)
        `IDLE: begin
          // When last data is sent, prepare for writing
          if (pe_we) begin
            wr_state_d = `WAIT;
          end else begin
            wr_state_d = `IDLE;
          end
        end
        `WAIT: begin
          // Wait for output latency
          if (lat_cnt_q == row_lat) begin
            wr_state_d = `BUSY;
          end else begin
            wr_state_d = `WAIT;
          end
        end
        `BUSY: begin
          // Busy lasts batch_n cycles
          if (lat_cnt_q == col_lat) begin
            wr_state_d = `DONE;
          end else begin
            wr_state_d = `BUSY;
          end
        end
        `DONE: begin
          // Lasts 1 cycle
          wr_state_d = `IDLE;
        end
        default: begin
          wr_state_d = `IDLE;
        end
      endcase
    end else begin
      wr_state_d = `IDLE;
    end
  end

  always @(*) begin
    case (wr_state_q)
      `WAIT: begin
        if (lat_cnt_q == row_lat) begin
          lat_cnt_d = 'd0;
        end else begin
          lat_cnt_d = lat_cnt_q + 'd1;
        end
      end
      `BUSY: begin
        if (lat_cnt_q == col_lat) begin
          lat_cnt_d = 'd0;
        end else begin
          lat_cnt_d = lat_cnt_q + 'd1;
        end
      end
      default: begin
        lat_cnt_d = 'd0;
      end
    endcase
  end

  // Main state machine behavior
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= `IDLE;
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
        // Until done reading and done writing
        if (!rd_en && wr_state_q == `DONE) begin
          state_d = `DONE;
        end else begin
          state_d = `BUSY;
        end
      end
      `DONE: begin
        // Wait for start_i being pulled down
        state_d = (!start_i)? `IDLE : `DONE;
      end
      default: begin
        state_d = `IDLE;
      end
    endcase
  end

endmodule

`endif
