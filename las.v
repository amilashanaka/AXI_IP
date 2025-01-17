`timescale 1 ns / 1 ps

module data_anchor #(
    parameter         DATA_WIDTH           = 32,    // Width of data samples
    parameter         TOTAL_SAMPLES        = 1024,  // Number of samples to collect
    parameter         ADC_MAX_COUNT        = 1,    // Max ADC cycles between samples
    parameter integer C_M_AXIS_TDATA_WIDTH = 32,
    parameter integer C_S_AXI_DATA_WIDTH   = 32,
    parameter integer C_S_AXI_ADDR_WIDTH   = 4
) (
    // AXI Master Stream Interface
    input  wire                                m_axis_aclk,     // AXI clock
    input  wire                                m_axis_aresetn,  // AXI reset (active-low)
    output reg                                 m_axis_tvalid,   // AXI data valid
    output reg  [    C_M_AXIS_TDATA_WIDTH-1:0] m_axis_tdata,    // AXI data
    output reg  [(C_M_AXIS_TDATA_WIDTH/8)-1:0] m_axis_tstrb,    // AXI byte enable
    output reg                                 m_axis_tlast,    // AXI last signal
    input  wire                                m_axis_tready,   // AXI ready signal

    // ADC interface
    input wire [DATA_WIDTH-1:0] chanel1,   // ADC channel 1 data
    input wire                  chan1_rdy, // ADC data ready signal
    output wire                 sample_ready,
    // AXI Slave Interface
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output wire s_axi_wready,
    output wire [1:0] s_axi_bresp,
    output wire s_axi_bvalid,
    input wire s_axi_bready,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rvalid,
    input wire s_axi_rready
);

  // Internal Signals
  reg [DATA_WIDTH-1:0] buffer1[0:TOTAL_SAMPLES-1];  // Buffer 1 for samples
  reg [DATA_WIDTH-1:0] buffer2[0:TOTAL_SAMPLES-1];  // Buffer 2 for samples
  integer sample_count = 0;  // Tracks samples collected
  integer adc_loop = 0;  // ADC delay counter
  integer stream_index = 0;  // Tracks samples transmitted
  reg new_data_ready = 1'b0;  // Flag indicating new data is ready
  reg buffer_ready = 1'b0;  // Flag indicating buffer is ready
  reg active_buffer = 1'b0;  // Active buffer flag (0 for buffer1, 1 for buffer2)
  reg  trans_done  = 1'b0;
  
  
  // FSM States
  localparam IDLE = 2'b00;
  localparam BUFFERING = 2'b01;
  localparam STREAMING = 2'b10;

  // AXI Slave Lite Interface
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
      .S_DDRY(sample_ready)
  );



  // Collect ADC Data
  always @(posedge m_axis_aclk) begin
  
// new_data_ready <= 1'b1;  // Clear new data flag
//    if (!m_axis_aresetn) begin
//     sample_count <= 0;
//      adc_loop <= 0;
//     //new_data_ready <= 1'b0;
//    end else begin
      if (chan1_rdy) begin
        if (adc_loop == ADC_MAX_COUNT) begin
          if (active_buffer == 1'b0) buffer1[sample_count] <= chanel1;
          else buffer2[sample_count] <= chanel1;

          sample_count <= sample_count + 1;
          adc_loop <= 0;

          if (sample_count == TOTAL_SAMPLES ) begin
            sample_count   <= 0;
            active_buffer  <= ~active_buffer;  // Switch active buffer
            new_data_ready <= 1'b1;  // Clear new data flag
            trans_done <= 1'b0; 
          end
        end else begin
          adc_loop <= adc_loop + 1;
        end
      end
      
      if(trans_done== 1'b1)
       new_data_ready <= 1'b0;  // Clear new data flag
//    end
  end


  // Stream Data to AXI Master Interface
  always @(posedge m_axis_aclk) begin
    if (!m_axis_aresetn) begin

      stream_index   <= 0;
      m_axis_tvalid  <= 0;
      m_axis_tdata   <= 0;
      m_axis_tstrb   <= {(C_M_AXIS_TDATA_WIDTH / 8) {1'b1}};  // Enable all bytes
      m_axis_tlast   <= 0;
    end else begin

      // Stream out data 
      if (m_axis_tready && sample_ready) begin

        if (active_buffer == 1'b0) m_axis_tdata <= buffer1[stream_index];
        else m_axis_tdata <= buffer2[stream_index];
        m_axis_tvalid <= 1;
        m_axis_tlast  <= (stream_index == TOTAL_SAMPLES - 1);
        stream_index  <= stream_index + 1;

        // complete data transfer
        if (stream_index == TOTAL_SAMPLES) begin
          stream_index   <= 0;
          trans_done<= 1'b0; 
    
          m_axis_tvalid  <= 0;
        end
      end
    end

  end

assign sample_ready = new_data_ready ;

endmodule
