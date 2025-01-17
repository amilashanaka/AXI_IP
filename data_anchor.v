`timescale 1 ns / 1 ps

module data_anchor #(
    parameter         DATA_WIDTH           = 32,    // Data width
    parameter         TOTAL_SAMPLES        = 1024,  // Samples to collect
    parameter integer C_M_AXIS_TDATA_WIDTH = 32,
    parameter integer C_S_AXI_DATA_WIDTH   = 32,
    parameter integer C_S_AXI_ADDR_WIDTH   = 4
) (
    // AXI Master Stream Interface
    input  wire                                m_axis_aclk,     // AXI clock
    input  wire                                m_axis_aresetn,  // AXI reset
    output reg                                 m_axis_tvalid,   // AXI valid signal
    output reg  [    C_M_AXIS_TDATA_WIDTH-1:0] m_axis_tdata,    // AXI data
    output reg                                 m_axis_tlast,    // AXI last signal
    input  wire                                m_axis_tready,   // AXI ready signal

    // ADC Interface
    input  wire [DATA_WIDTH-1:0]               chanel1,         // ADC data
    input  wire                                chan1_rdy,       // ADC ready signal

    // AXI Slave Lite Interface
    input  wire                                s_axi_aclk,
    input  wire                                s_axi_aresetn,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_awaddr,
    input  wire [2:0]                          s_axi_awprot,
    input  wire                                s_axi_awvalid,
    output wire                                s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]       s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   s_axi_wstrb,
    input  wire                                s_axi_wvalid,
    output wire                                s_axi_wready,
    output wire [1:0]                          s_axi_bresp,
    output wire                                s_axi_bvalid,
    input  wire                                s_axi_bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_araddr,
    input  wire [2:0]                          s_axi_arprot,
    input  wire                                s_axi_arvalid,
    output wire                                s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1:0]       s_axi_rdata,
    output wire [1:0]                          s_axi_rresp,
    output wire                                s_axi_rvalid,
    input  wire                                s_axi_rready
);

  // Internal Signals
  reg [DATA_WIDTH-1:0] buffer1[0:TOTAL_SAMPLES-1];  // Sample buffer
  integer              sample_count;               // Sample index
  integer              stream_index;               // Stream index
  reg                  chan1_rdy_d;                // Delayed version of chan1_rdy
  wire                 chan1_rdy_posedge;          // Positive edge detect
  reg                  new_data_ready;             // Data ready flag

  // AXI Slave Lite Instance
  anchor_slave_lite_v1_0_S_AXI #(
      .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
      .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
  ) anchor_slave_lite_inst (
      .S_AXI_ACLK(s_axi_aclk),
      .S_AXI_ARESETN(s_axi_aresetn),
      .S_AXI_AWADDR(s_axi_awaddr),
      .S_AXI_AWPROT(s_axi_awprot),
      .S_AXI_AWVALID(s_axi_awvalid),
      .S_AXI_AWREADY(s_axi_awready),
      .S_AXI_WDATA(s_axi_wdata),
      .S_AXI_WSTRB(s_axi_wstrb),
      .S_AXI_WVALID(s_axi_wvalid),
      .S_AXI_WREADY(s_axi_wready),
      .S_AXI_BRESP(s_axi_bresp),
      .S_AXI_BVALID(s_axi_bvalid),
      .S_AXI_BREADY(s_axi_bready),
      .S_AXI_ARADDR(s_axi_araddr),
      .S_AXI_ARPROT(s_axi_arprot),
      .S_AXI_ARVALID(s_axi_arvalid),
      .S_AXI_ARREADY(s_axi_arready),
      .S_AXI_RDATA(s_axi_rdata),
      .S_AXI_RRESP(s_axi_rresp),
      .S_AXI_RVALID(s_axi_rvalid),
      .S_AXI_RREADY(s_axi_rready),
      .S_DDRY(new_data_ready)
  );

  // Positive Edge Detection for chan1_rdy
  assign chan1_rdy_posedge = chan1_rdy && !chan1_rdy_d;

  // Sequential Logic for Sample Collection and AXI Stream Transmission
  always @(posedge m_axis_aclk or negedge m_axis_aresetn) begin
    if (!m_axis_aresetn) begin
      sample_count   <= 0;
      stream_index   <= 0;
      m_axis_tvalid  <= 1'b0;
      m_axis_tlast   <= 1'b0;
      new_data_ready <= 1'b0;
      chan1_rdy_d    <= 1'b0;
    end else begin
      // Rising edge detection
      chan1_rdy_d <= chan1_rdy;

      // Sample collection on positive edge
      if (chan1_rdy_posedge && !new_data_ready) begin
        buffer1[sample_count] <= chanel1;
        sample_count <= sample_count + 1;

        if (sample_count == TOTAL_SAMPLES - 1) begin
          new_data_ready <= 1'b1;  // Signal data ready
          sample_count   <= 0;     // Reset counter
        end
      end

      // AXI Stream Transmission
      if (m_axis_tready && new_data_ready) begin
        m_axis_tdata  <= buffer1[stream_index];
        m_axis_tvalid <= 1'b1;
        m_axis_tlast  <= (stream_index == TOTAL_SAMPLES - 1);
        stream_index <= stream_index + 1;
        if (m_axis_tlast) begin
          stream_index   <= 0;
          new_data_ready <= 1'b0;  // Reset data ready flag
          m_axis_tvalid  <= 1'b0;
        end

      end 
    end
  end

endmodule