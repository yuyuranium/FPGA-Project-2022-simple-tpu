`ifndef _DEF_V
`define _DEF_V

// Common definitions
`define DATA_WIDTH 16    // A data is a 16-bit fixed-point number
`define WORD_WIDTH 128   // A word in global buffer has 8 of data
`define ADDR_WIDTH 12    // Global buffer has 4096 entries
`define OUTPUT_LAT 2     // Latency to the output when the batch ends

// Data positions in a word (little endian)
`define DATA7 127:112
`define DATA6 111:96
`define DATA5 95:80
`define DATA4 79:64
`define DATA3 63:48
`define DATA2 47:32
`define DATA1 31:16
`define DATA0 15:0

// Simulation definitions
`define GBUFF_ADDR_BEGIN 12'h000  // Simulate only 256 entries (3840~4095)
`define GBUFF_ADDR_END   12'hfff

`endif
