module fir_filter #(
    parameter NUM_TAPS = 49  // Number of filter coefficients (taps)
) (
    input  wire               clk,          // System clock
    input  wire               reset,        // Synchronous reset
    input  wire               data_in_clk,  // Clock enable for data input
    input  wire signed [15:0] data_in,      // Input data sample
    output wire signed [15:0] data_out      // Filtered output data
);

  // Normalized filter coefficients (signed 16-bit, scaled to sum = 32768 for gain of 1)
  wire signed [15:0] tap    [0:NUM_TAPS-1];

  // Registers for multiplications and summations
  (* use_dsp = "no" *)reg signed  [31:0] samples[0:NUM_TAPS-1];  // Stores products of coefficients and input
  (* use_dsp = "no" *)reg signed  [31:0] sum    [  0:NUM_TAPS];  // Accumulates filter results

  integer            i;

  // Normalized coefficient assignments
  assign tap[0]  = 16'h0009;
  assign tap[1]  = 16'h0012;
  assign tap[2]  = 16'h0016;
  assign tap[3]  = 16'h0011;
  assign tap[4]  = 16'h0000;
  assign tap[5]  = 16'hFF64;
  assign tap[6]  = 16'hFEF7;
  assign tap[7]  = 16'hFEC5;
  assign tap[8]  = 16'hFEF7;
  assign tap[9]  = 16'h0000;
  assign tap[10] = 16'h005D;
  assign tap[11] = 16'h00B2;
  assign tap[12] = 16'h00D4;
  assign tap[13] = 16'h009E;
  assign tap[14] = 16'h0000;
  assign tap[15] = 16'hFF0C;
  assign tap[16] = 16'hFE19;
  assign tap[17] = 16'hFDC9;
  assign tap[18] = 16'hFE47;
  assign tap[19] = 16'h0000;
  assign tap[20] = 16'h02CC;
  assign tap[21] = 16'h064E;
  assign tap[22] = 16'h0967;
  assign tap[23] = 16'h0BD6;
  assign tap[24] = 16'h0C7D;
  assign tap[25] = 16'h0BD6;
  assign tap[26] = 16'h0967;
  assign tap[27] = 16'h064E;
  assign tap[28] = 16'h02CC;
  assign tap[29] = 16'h0000;
  assign tap[30] = 16'hFE47;
  assign tap[31] = 16'hFDC9;
  assign tap[32] = 16'hFE19;
  assign tap[33] = 16'hFF0C;
  assign tap[34] = 16'h0000;
  assign tap[35] = 16'h009E;
  assign tap[36] = 16'h00D4;
  assign tap[37] = 16'h00B2;
  assign tap[38] = 16'h005D;
  assign tap[39] = 16'h0000;
  assign tap[40] = 16'hFEF7;
  assign tap[41] = 16'hFEC5;
  assign tap[42] = 16'hFEF7;
  assign tap[43] = 16'hFF64;
  assign tap[44] = 16'h0000;
  assign tap[45] = 16'h0011;
  assign tap[46] = 16'h0016;
  assign tap[47] = 16'h0012;
  assign tap[48] = 16'h0009;

  // Main FIR filter logic
  always @(posedge clk) begin
    if (!reset) begin
      // Reset all registers to zero
      for (i = 0; i < NUM_TAPS; i = i + 1) begin
        samples[i] <= 0;
        sum[i] <= 0;
      end
      sum[NUM_TAPS] <= 0;
    end else if (data_in_clk) begin
      for (i = 0; i < NUM_TAPS; i = i + 1) begin
        samples[i] <= tap[i] * data_in;  // Compute multiplication
        sum[i] <= sum[i+1] + samples[i];  // Perform FIR filtering
      end
    end
  end

  // Output the filtered data (most significant 16 bits of the sum)
  assign data_out = sum[0][31:16];

endmodule
