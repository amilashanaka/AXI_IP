`timescale 1 ns / 1 ps

module Pynq_write_slave_lite_v1_0_S_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output reg S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output reg S_AXI_WREADY,
    output reg [1:0] S_AXI_BRESP,
    output reg S_AXI_BVALID,
    input wire S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire [2:0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output reg S_AXI_ARREADY,
    output reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0] S_AXI_RRESP,
    output reg S_AXI_RVALID,
    input wire S_AXI_RREADY
);

    // Local parameters
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    // State registers
    reg [1:0] write_state, read_state;
    localparam IDLE = 2'b00, WRITE = 2'b01, READ = 2'b10;

    // Registers for storing data
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr, axi_araddr;

    // Reset logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY <= 1'b0;
            S_AXI_BVALID <= 1'b0;
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID <= 1'b0;
            write_state <= IDLE;
            read_state <= IDLE;
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            // Write State Machine
            case (write_state)
                IDLE: begin
                    if (S_AXI_AWVALID) begin
                        S_AXI_AWREADY <= 1'b1;
                        axi_awaddr <= S_AXI_AWADDR;
                        write_state <= WRITE;
                    end
                end
                WRITE: begin
                    if (S_AXI_WVALID) begin
                        S_AXI_WREADY <= 1'b1;
                        case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                            2'b00: slv_reg0 <= S_AXI_WDATA;
                            2'b01: slv_reg1 <= S_AXI_WDATA;
                            2'b10: slv_reg2 <= S_AXI_WDATA;
                            2'b11: slv_reg3 <= S_AXI_WDATA;
                        endcase
                        S_AXI_BRESP <= 2'b00; // OKAY response
                        S_AXI_BVALID <= 1'b1;
                        write_state <= IDLE;
                    end
                end
            endcase

            // Read State Machine
            case (read_state)
                IDLE: begin
                    if (S_AXI_ARVALID) begin
                        S_AXI_ARREADY <= 1'b1;
                        axi_araddr <= S_AXI_ARADDR;
                        read_state <= READ;
                    end
                end
                READ: begin
                    if (S_AXI_RREADY) begin
                        S_AXI_RVALID <= 1'b1;
                        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                            2'b00: S_AXI_RDATA <= slv_reg0;
                            2'b01: S_AXI_RDATA <= slv_reg1;
                            2'b10: S_AXI_RDATA <= slv_reg2;
                            2'b11: S_AXI_RDATA <= slv_reg3;
                        endcase
                        S_AXI_RRESP <= 2'b00; // OKAY response
                        read_state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
