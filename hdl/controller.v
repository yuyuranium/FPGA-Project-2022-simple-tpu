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
  output pe_clr_o,
  output pe_we_o,

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

  output reg [2:0]             wordp_sel_o,
  output reg [7:0]             datap_we_o
);

  // Main state
  reg [1:0] state_q, state_d;

  // Boundaries for batches (constant)
  wire [`ADDR_WIDTH-1:0] n_row_batches  = m_i + 'h008 - 'h001 >> 3;   // m / 8
  wire [`ADDR_WIDTH-1:0] n_col_batches  = n_i + 'h008 - 'h001 >> 3;   // n / 8
  wire [`ADDR_WIDTH-1:0] n_batch_cycles = k_i < 'h008 ? 'h008 : k_i;  // >= 8

  // Counters for batches
  reg [`ADDR_WIDTH-1:0] row_batch_q, row_batch_d;
  reg [`ADDR_WIDTH-1:0] col_batch_q, col_batch_d;
  reg [`ADDR_WIDTH-1:0] batch_cycle_q, batch_cycle_d;

  // Global buffer read/write enable
  wire rd_en = rd_state_q == `BUSY && !bubble_d;
  wire wr_en = wr_state_q == `BUSY;

  // Base source addresses
  wire [`ADDR_WIDTH-1:0] batch_base_addra = row_batch_q * k_i + base_addra_i;
  wire [`ADDR_WIDTH-1:0] batch_base_addrb = col_batch_q * k_i + base_addrb_i;

  // Source address generator
  reg  [1:0] rd_state_q, rd_state_d;

  // Target address
  reg  [`ADDR_WIDTH-1:0] addrp_q, addrp_d;

  // Target address generator (old)
  /* wire [3:0] row_lat = `OUTPUT_LAT + batch_m - 4'h1;  // Row latency */
  /* wire [3:0] col_lat = batch_n - 4'h1;                // Column latency */
  reg  [1:0] wr_state_q, wr_state_d;                  // Write state
  /* reg  [3:0] lat_cnt_q, lat_cnt_d;                    // Latency counter */
  // Target address generator
  reg  [8+`OUTPUT_LAT-1:0] row_lat_shift_reg_q;
  reg  [7:0] row_lat_mask_q, row_lat_mask_d;
  reg  [2:0] col_lat_cnt_q, col_lat_cnt_d;
  wire       wr_start = |(row_lat_mask_q & row_lat_shift_reg_q[7+`OUTPUT_LAT:`OUTPUT_LAT]);
  reg  [`ADDR_WIDTH-1:0] wr_col_batch_q, wr_col_batch_d;

  // Boundary conditions
  wire row_batch_end = row_batch_q == n_row_batches - 'd1;
  wire col_batch_end = col_batch_q == n_col_batches - 'd1;
  wire batch_end     = batch_cycle_q == n_batch_cycles - 'd1;
  wire wr_col_batch_end = wr_col_batch_q == n_col_batches - 'd1;

  /* wire [2:0] rem_m   = m_i[2:0] & 3'b111;      // m % 8 */
  wire [2:0] rem_n   = n_i[2:0] & 3'b111;      // n % 8
  /* wire [2:0] batch_m = row_batch_end ? rem_m - 3'd1 : 3'd7; */
  wire [2:0] batch_n = wr_col_batch_end ? rem_n - 3'd1 : 3'd7; 

  // PE control signals
  reg  pe_clr_q, pe_we_q, ensys_q, bubble_q;
  wire bubble_d = batch_cycle_q > (k_i - 1);     // Insert bubbles when > k

  // Assign output signals
  assign valid_o  = state_q == `DONE;
  assign pe_we_o  = pe_we_q;
  assign pe_clr_o = pe_clr_q;               // New batch data is sent
  assign ensys_o  = ensys_q;
  assign bubble_o = bubble_q;

  // Global buffer interfaces
  assign ena_o   = rd_en;    // Enable when read enable
  assign wea_o   = 1'b0;     // Always read
  assign addra_o = rd_en ? batch_base_addra + batch_cycle_q : 'd0;

  assign enb_o   = rd_en;    // Enable when read enable
  assign web_o   = 1'b0;     // Always read
  assign addrb_o = rd_en ? batch_base_addrb + batch_cycle_q : 'd0;

  assign enp_o   = wr_en;    // Enable when write enable
  assign wep_o   = wr_en;    // Write enable when write enable
  assign addrp_o = wr_en ? base_addrp_i + addrp_q : 'd0;

  always @(*) begin
    datap_we_o = 8'hff;
    /* if (wr_en) begin */
    /*   case (batch_m) */
    /*     3'o0: */
    /*       datap_we_o = 8'b00000001; */
    /*     3'o1: */
    /*       datap_we_o = 8'b00000011; */
    /*     3'o2: */
    /*       datap_we_o = 8'b00000111; */
    /*     3'o3: */
    /*       datap_we_o = 8'b00001111; */
    /*     3'o4: */
    /*       datap_we_o = 8'b00011111; */
    /*     3'o5: */
    /*       datap_we_o = 8'b00111111; */
    /*     3'o6: */
    /*       datap_we_o = 8'b01111111; */
    /*     3'o7: */
    /*       datap_we_o = 8'b11111111; */
    /*     default: */
    /*       datap_we_o = 8'b00000000; */
    /*   endcase */
    /* end else begin */
    /*   datap_we_o = 8'b00000000; */
    /* end */
  end

  always @(*) begin
    if (wr_en) begin
      wordp_sel_o = col_lat_cnt_q[2:0];
    end else begin
      wordp_sel_o = 'o0;
    end
  end

  // PE control signals
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pe_clr_q <= 1'b0;
      pe_we_q  <= 1'b0;
      ensys_q  <= 1'b0;
      bubble_q <= 1'b0;
    end else begin
      if (state_q == `BUSY) begin
        pe_clr_q <= ~|batch_cycle_q;
        pe_we_q  <= batch_cycle_d == (k_i - 'd1);  // Last data is sent 
        ensys_q  <= state_q == `BUSY;
        bubble_q <= bubble_d;
      end
    end
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
    if (rd_state_q == `IDLE) begin
      row_batch_d = 'd0;
    end else if (rd_state_q == `BUSY) begin
      if (row_batch_end && col_batch_end && batch_end) begin
        row_batch_d = 'd0;                // Reset when all end
      end else if (col_batch_end && batch_end) begin
        row_batch_d = row_batch_q + 'd1;  // Increment as col batch ends
      end else begin
        row_batch_d = row_batch_q;        // Remain unchanged
      end
    end else begin
      row_batch_d = row_batch_q;
    end
  end

  // Column batch counter (medium)
  always @(*) begin
    if (rd_state_q == `IDLE) begin
      col_batch_d = 'd0;
    end else if (rd_state_q == `BUSY) begin
      if (col_batch_end && batch_end) begin
        col_batch_d = 'd0;                // Reset when column batch ends
      end else if (batch_end) begin
        col_batch_d = col_batch_q + 'd1;  // Increment as batch ends
      end else begin
        col_batch_d = col_batch_q;        // Remain unchanged
      end
    end else begin
      col_batch_d = col_batch_q;
    end
  end

  // Batch cycle counter (fastest)
  always @(*) begin
    if (rd_state_q == `BUSY) begin            // when read enable
      if (batch_end) begin
        batch_cycle_d = 'd0;                  // Reset when ends
      end else begin
        batch_cycle_d = batch_cycle_q + 'd1;  // Increment every cycle
      end
    end else begin
      batch_cycle_d = 'd0;
    end
  end

  // Source address generator state machine behavior
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_state_q <= `IDLE;
    end else begin
      rd_state_q <= rd_state_d;
    end
  end

  always @(*) begin
    case (rd_state_q)
      `IDLE:
        rd_state_d = state_q == `BUSY ? `BUSY : `IDLE;
      `BUSY:
        rd_state_d =
          row_batch_end && col_batch_end && batch_end ? `DONE : `BUSY;
      `DONE:
        rd_state_d = state_q == `DONE ? `IDLE : `DONE;
      default: begin
        rd_state_d = `IDLE;
      end
    endcase
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      row_lat_shift_reg_q <= 'd0;
    end else begin
      row_lat_shift_reg_q <=
        { row_lat_shift_reg_q[8+`OUTPUT_LAT-2:0], pe_we_q };
    end
  end

  // Target address generation
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      row_lat_mask_q <= 'd0;
    end else begin
      if (batch_end) begin
        row_lat_mask_q <= row_lat_mask_d;
      end
    end
  end

  always @(*) begin
    row_lat_mask_d = 8'b10000000;
    /* if (state_q == `BUSY) begin */
    /*   if (row_batch_end) begin */
    /*     case (batch_m) */
    /*       3'o0: */
    /*         row_lat_mask_d = 8'b00000001; */
    /*       3'o1: */
    /*         row_lat_mask_d = 8'b00000010; */
    /*       3'o2: */
    /*         row_lat_mask_d = 8'b00000100; */
    /*       3'o3: */
    /*         row_lat_mask_d = 8'b00001000; */
    /*       3'o4: */
    /*         row_lat_mask_d = 8'b00010000; */
    /*       3'o5: */
    /*         row_lat_mask_d = 8'b00100000; */
    /*       3'o6: */
    /*         row_lat_mask_d = 8'b01000000; */
    /*       3'o7: */
    /*         row_lat_mask_d = 8'b10000000; */
    /*       default: */
    /*         row_lat_mask_d = 8'b00000000; */
    /*     endcase */
    /*   end else begin */
    /*     row_lat_mask_d = 8'b10000000; */
    /*   end */
    /* end else begin */
    /*   row_lat_mask_d = 8'b00000000; */
    /* end */
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_col_batch_q <= 'd0;
    end else begin
      wr_col_batch_q <= wr_col_batch_d;
    end
  end

  always @(*) begin
    if (state_q == `BUSY) begin
      if (col_lat_cnt_q == batch_n) begin
        if (wr_col_batch_q == n_col_batches - 1) begin
          wr_col_batch_d = 'd0;
        end else begin
          wr_col_batch_d = wr_col_batch_q + 'd1;
        end
      end else begin
        wr_col_batch_d = wr_col_batch_q;
      end
    end else begin
      wr_col_batch_d = 'd0;
    end
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_state_q <= `IDLE;
    end else begin
      wr_state_q <= wr_state_d;
    end
  end

  always @(*) begin
    if (state_q == `BUSY) begin
      case (wr_state_q)
        `IDLE: begin
          if (wr_start) begin
            wr_state_d = `BUSY;
          end else begin
            wr_state_d = `IDLE;
          end
        end
        `BUSY: begin
          if (wr_start) begin
            wr_state_d = `BUSY;
          end else if (col_lat_cnt_q == batch_n) begin
            if (|row_lat_shift_reg_q) begin
              wr_state_d = `IDLE;
            end else begin
              wr_state_d = `DONE;  // No pending writing
            end
          end else begin
            wr_state_d = `BUSY;
          end
        end
        `DONE: begin
          wr_state_d = state_q == `DONE ? `IDLE : `DONE;
        end
        default: begin
          wr_state_d = `IDLE;
        end
      endcase
    end else begin
      wr_state_d = `IDLE;
    end
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      col_lat_cnt_q <= 'd0;
    end else begin
      col_lat_cnt_q <= col_lat_cnt_d;
    end
  end

  always @(*) begin
    if (state_q == `BUSY) begin
      case (wr_state_q)
        `IDLE: begin
          col_lat_cnt_d = 'd0;
        end
        `BUSY: begin
          if (wr_start) begin
            col_lat_cnt_d = 'd0;
          end else if (col_lat_cnt_q == batch_n) begin
            col_lat_cnt_d = 'd0;
          end else begin
            col_lat_cnt_d = col_lat_cnt_q + 'd1;
          end
        end
        `DONE: begin
          col_lat_cnt_d = 'd0;
        end
        default: begin
          col_lat_cnt_d = 'd0;
        end
      endcase
    end else begin
      col_lat_cnt_d = 'd0;
    end
  end

  // Target address generation
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      addrp_q <= 'd0;
    end else begin
      addrp_q <= addrp_d;
    end
  end

  always @(*) begin
    if (wr_en) begin
      addrp_d = addrp_q + 'd1;
    end else begin
      addrp_d = addrp_q;  // unchanged
    end
  end

  // Target address generator state machine behavior
  /* always @(posedge clk_i or negedge rst_ni) begin */
  /*   if (!rst_ni) begin */
  /*     wr_state_q <= `IDLE; */
  /*     lat_cnt_q  <= 'd0; */
  /*   end else begin */
  /*     wr_state_q <= wr_state_d; */
  /*     lat_cnt_q  <= lat_cnt_d; */
  /*   end */
  /* end */

  /* always @(*) begin */
  /*   if (state_q == `BUSY) begin */
  /*     case (wr_state_q) */
  /*       `IDLE: begin */
  /*         // When last data is sent, prepare for writing */
  /*         if (pe_we_o) begin */
  /*           wr_state_d = `WAIT; */
  /*         end else begin */
  /*           wr_state_d = `IDLE; */
  /*         end */
  /*       end */
  /*       `WAIT: begin */
  /*         // Wait for output latency */
  /*         if (lat_cnt_q == row_lat) begin */
  /*           wr_state_d = `BUSY; */
  /*         end else begin */
  /*           wr_state_d = `WAIT; */
  /*         end */
  /*       end */
  /*       `BUSY: begin */
  /*         // Busy lasts batch_n cycles */
  /*         if (lat_cnt_q == col_lat) begin */
  /*           wr_state_d = `DONE; */
  /*         end else begin */
  /*           wr_state_d = `BUSY; */
  /*         end */
  /*       end */
  /*       `DONE: begin */
  /*         // Lasts 1 cycle */
  /*         wr_state_d = `IDLE; */
  /*       end */
  /*       default: begin */
  /*         wr_state_d = `IDLE; */
  /*       end */
  /*     endcase */
  /*   end else begin */
  /*     wr_state_d = `IDLE; */
  /*   end */
  /* end */

  /* always @(*) begin */
  /*   case (wr_state_q) */
  /*     `WAIT: begin */
  /*       if (lat_cnt_q == row_lat) begin */
  /*         lat_cnt_d = 'd0; */
  /*       end else begin */
  /*         lat_cnt_d = lat_cnt_q + 'd1; */
  /*       end */
  /*     end */
  /*     `BUSY: begin */
  /*       if (lat_cnt_q == col_lat) begin */
  /*         lat_cnt_d = 'd0; */
  /*       end else begin */
  /*         lat_cnt_d = lat_cnt_q + 'd1; */
  /*       end */
  /*     end */
  /*     default: begin */
  /*       lat_cnt_d = 'd0; */
  /*     end */
  /*   endcase */
  /* end */

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
        state_d = start_i ? `BUSY : `IDLE;
      end
      `BUSY: begin
        // Until done reading and done writing
        if (rd_state_q == `DONE && wr_state_q == `DONE) begin
          state_d = `DONE;
        end else begin
          state_d = `BUSY;
        end
      end
      `DONE: begin
        // Wait for start_i being pulled down
        state_d = !start_i ? `IDLE : `DONE;
      end
      default: begin
        state_d = `IDLE;
      end
    endcase
  end

endmodule

`endif
