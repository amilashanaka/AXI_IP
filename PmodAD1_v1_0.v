`timescale 1 ns / 1 ps

module PmodAD1_v1_0 #(
    parameter INCLUDE_DEBUG_INTERFACE = 0,
    parameter AD1_CLOCKS_PER_BIT = 20,         // 1 bit per 200ns
    parameter AD1_CLOCKS_BEFORE_DATA = 60,    // 600ns
    parameter AD1_CLOCKS_AFTER_DATA = 500,    // 5us
    parameter AD1_CLOCKS_BETWEEN_TRANSACTIONS = 400
) (
    input  wire        clk,          // Clock signal
    input  wire        reset_n,      // Active-low reset
    output wire        dout_a_rdy,     // Data ready flag A
     output wire       dout_b_rdy,     // Data ready flag B
    output wire [1:0]  led,          // LED status
    output wire [15:0] data_a,         // Output data
    output wire [15:0] data_b,         // Output data
    
    // Pmod interface pins
    input  wire        Pmod_out_pin10_i,
    output wire        Pmod_out_pin10_o,
    output wire        Pmod_out_pin10_t,
    input  wire        Pmod_out_pin1_i,
    output wire        Pmod_out_pin1_o,
    output wire        Pmod_out_pin1_t,
    input  wire        Pmod_out_pin2_i,
    output wire        Pmod_out_pin2_o,
    output wire        Pmod_out_pin2_t,
    input  wire        Pmod_out_pin3_i,
    output wire        Pmod_out_pin3_o,
    output wire        Pmod_out_pin3_t,
    input  wire        Pmod_out_pin4_i,
    output wire        Pmod_out_pin4_o,
    output wire        Pmod_out_pin4_t,
    input  wire        Pmod_out_pin7_i,
    output wire        Pmod_out_pin7_o,
    output wire        Pmod_out_pin7_t,
    input  wire        Pmod_out_pin8_i,
    output wire        Pmod_out_pin8_o,
    output wire        Pmod_out_pin8_t,
    input  wire        Pmod_out_pin9_i,
    output wire        Pmod_out_pin9_o,
    output wire        Pmod_out_pin9_t
);

    // Internal signals
    wire ad1_cs, ad1_sdin0, ad1_sdin1, ad1_sclk;
    wire [31:0] ad1_data;
    reg  [31:0] ad1_data_r;
    wire drdy;

    // Pmod bridge instantiation
    pmod_bridge_0 PmodAD1_pmod_bridge (
        .out0_I(Pmod_out_pin1_i), .out0_O(Pmod_out_pin1_o), .out0_T(Pmod_out_pin1_t),
        .out1_I(Pmod_out_pin2_i), .out1_O(Pmod_out_pin2_o), .out1_T(Pmod_out_pin2_t),
        .out2_I(Pmod_out_pin3_i), .out2_O(Pmod_out_pin3_o), .out2_T(Pmod_out_pin3_t),
        .out3_I(Pmod_out_pin4_i), .out3_O(Pmod_out_pin4_o), .out3_T(Pmod_out_pin4_t),
        .out4_I(Pmod_out_pin7_i), .out4_O(Pmod_out_pin7_o), .out4_T(Pmod_out_pin7_t),
        .out5_I(Pmod_out_pin8_i), .out5_O(Pmod_out_pin8_o), .out5_T(Pmod_out_pin8_t),
        .out6_I(Pmod_out_pin9_i), .out6_O(Pmod_out_pin9_o), .out6_T(Pmod_out_pin9_t),
        .out7_I(Pmod_out_pin10_i), .out7_O(Pmod_out_pin10_o), .out7_T(Pmod_out_pin10_t),
        .in0_O(ad1_cs), .in0_T(1'b0),
        .in1_I(ad1_sdin0), .in1_T(1'b1),
        .in2_I(ad1_sdin1), .in2_T(1'b1),
        .in3_O(ad1_sclk), .in3_T(1'b0)
    );

    // SPI module instantiation
    ad1_spi #(
        .INCLUDE_DEBUG_INTERFACE(INCLUDE_DEBUG_INTERFACE),
        .CLOCKS_PER_BIT(AD1_CLOCKS_PER_BIT),
        .CLOCKS_BEFORE_DATA(AD1_CLOCKS_BEFORE_DATA),
        .CLOCKS_AFTER_DATA(AD1_CLOCKS_AFTER_DATA),
        .CLOCKS_BETWEEN_TRANSACTIONS(AD1_CLOCKS_BETWEEN_TRANSACTIONS)
    ) m_ad1_spi (
        .clk(clk),
        .rst(~reset_n),  // Active-low reset converted to active-high for SPI
        .cs(ad1_cs),
        .sdin0(ad1_sdin0),
        .sdin1(ad1_sdin1),
        .sclk(ad1_sclk),
        .drdy(drdy),
        .dout0(ad1_data[15:0]),
        .dout1(ad1_data[31:16]),
        .led(led)
    );

    // Register output data when drdy is high
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            ad1_data_r <= 32'd0;
        else if (drdy)
            ad1_data_r <= ad1_data;
    end

    // Assign outputs
    assign data_a = ad1_data_r[15:0];
    assign data_b = ad1_data_r[31:16];
    assign dout_a_rdy = drdy;
    assign dout_b_rdy = drdy;

endmodule
