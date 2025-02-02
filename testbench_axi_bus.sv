module top_axi_bus_tb;
  localparam BAUD_RATE = 1;
  localparam CLOCK_FREQUENCY = 32;
  parameter UART_ADDRESS = 32'h1000_0000;

  logic        mem_axi_awvalid;
  logic        mem_axi_awready;
  logic [31:0] mem_axi_awaddr;
  logic [ 2:0] mem_axi_awprot;
  logic        mem_axi_wvalid;
  logic        mem_axi_wready;
  logic [31:0] mem_axi_wdata;
  logic [ 3:0] mem_axi_wstrb;
  logic        mem_axi_bvalid;
  logic        mem_axi_bready;
  logic        mem_axi_arvalid;
  logic        mem_axi_arready;
  logic [31:0] mem_axi_araddr;
  logic [ 2:0] mem_axi_arprot;
  logic        mem_axi_rvalid;
  logic        mem_axi_rready;
  logic [31:0] mem_axi_rdata;
  logic        clk;
  logic        resetn;
  logic        uart_tx_out;

  axi_bus #(
      .UART_ADDRESS  (32'h1000_0000),
      .MEMORY_ADDRESS(32'h0000_0000)
  ) dut (
      .*
  );

  axi_bus_tb #(
      .UART_ADDRESS  (32'h1000_0000),
      .MEMORY_ADDRESS(32'h0000_0000)
  ) tb (
      .*
  );

  initial begin
    clk = 0;
    resetn = 0;
    resetn <= #1 1;
    forever begin
      #2 clk = ~clk;
    end
  end
endmodule

program axi_bus_tb #(
    parameter UART_ADDRESS   = 32'h1000_0000,
    parameter MEMORY_ADDRESS = 32'h0000_0000
) (
    output logic        mem_axi_awvalid,
    input               mem_axi_awready,
    output logic [31:0] mem_axi_awaddr,
    output logic [ 2:0] mem_axi_awprot,

    output logic        mem_axi_wvalid,
    input               mem_axi_wready,
    output logic [31:0] mem_axi_wdata,
    output logic [ 3:0] mem_axi_wstrb,

    input mem_axi_bvalid,
    output logic mem_axi_bready,

    output logic        mem_axi_arvalid,
    input               mem_axi_arready,
    output logic [31:0] mem_axi_araddr,
    output logic [ 2:0] mem_axi_arprot,

    input               mem_axi_rvalid,
    output logic        mem_axi_rready,
    input        [31:0] mem_axi_rdata,

    output logic clk,
    output logic resetn,

    input uart_tx_out
);
  initial begin
    mem_axi_awvalid = 1;
    mem_axi_awaddr  = MEMORY_ADDRESS;
    @(posedge clk);
    mem_axi_awvalid = 0;
    mem_axi_wvalid  = 1;
    mem_axi_wdata   = 32'hFFFF0000;
    mem_axi_wstrb   = 4'b1111;
    @(posedge clk);
    mem_axi_wvalid  = 0;
    mem_axi_awvalid = 0;
    mem_axi_bready  = 1;
    repeat (2) @(posedge clk);
    mem_axi_arvalid = 1;
    mem_axi_araddr  = MEMORY_ADDRESS;
    @(posedge clk);
    mem_axi_arvalid = 0;
    mem_axi_rready  = 1;
    @(posedge clk);
    mem_axi_rready = 0;
    @(posedge clk);
    $finish;
  end
endprogram
