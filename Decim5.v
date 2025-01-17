
`timescale 1 ns / 1 ps

	module Decim5 #
	(
	    parameter NUM_TAPS = 49,
       parameter integer DESIM = 5  // Decimation factor
 
	)
	(
	 input  wire        clk,       // System clock
    input  wire        reset_n,   // Active-low reset
    input  wire [15:0] data_in,   // 16-bit input data
    output wire [15:0] data_out,  // 16-bit output data
    input  wire        din_rdy,   // Data ready signal for input
    output wire        dout_rdy,  // Data ready signal for output
    input  wire        en         // Enable signal
	);
	
  // Internal registers
  reg  [ 7:0] sample_count;  // Counter for decimation
  wire [15:0] filtered_data;  // Filtered output data
  reg         dout_rdy_flg;  // Internal flag for dout_rdy
  reg         din_rdy_d;  // Delayed version of din_rdy for edge detection
  wire        din_rdy_posedge;  // Rising edge detection for din_rdy

  // Detect the rising edge of din_rdy
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      din_rdy_d <= 1'b0;
    end else begin
      din_rdy_d <= din_rdy;
    end
  end

  assign din_rdy_posedge = din_rdy & ~din_rdy_d;



  // Instantiate FIR filter and pass the TAPS parameter
  fir_filter #(
      .NUM_TAPS(NUM_TAPS)
  ) fir_filter_inst (
      .clk        (clk),              // System clock
      .reset      (reset_n),          // Reset signal
      .data_in    (data_in),          // Input data to filter
      .data_in_clk(din_rdy_posedge),
      .data_out   (filtered_data)     // Filtered output
  );

  // Decimation filter logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sample_count <= 8'd0;
      dout_rdy_flg <= 1'b0;
    end else if (en) begin
      if (din_rdy_posedge) begin
        sample_count <= sample_count + 1;

        // Output filtered value when count matches decimation factor
        if (sample_count == DESIM - 1) begin
          dout_rdy_flg <= 1'b1;  // Indicate new data is ready
          sample_count <= 8'd0;  // Reset sample counter
        end else begin
          dout_rdy_flg <= 1'b0;  // No new data ready
        end
      end
    end else begin
      dout_rdy_flg <= 1'b0;  // Clear dout_rdy
    end
  end
  // Assign the output data
  assign data_out = en ? filtered_data : data_in;
  // assign data_out =  data_in;
  assign dout_rdy = en ? dout_rdy_flg : din_rdy;

endmodule
