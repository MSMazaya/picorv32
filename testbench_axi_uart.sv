module top_axi_uart_tb;
  localparam BAUD_RATE = 1;
  localparam CLOCK_FREQUENCY = 32;
  parameter UART_ADDRESS = 32'h1000_0000;

  logic        clk;
  logic        resetn;
  logic        awvalid;
  logic        awready;
  logic [31:0] awaddr;
  logic [ 2:0] awprot;
  logic        wvalid;
  logic        wready;
  logic [31:0] wdata;
  logic [ 3:0] wstrb;
  logic        bvalid;
  logic        bready;
  logic        arvalid;
  logic        arready;
  logic [31:0] araddr;
  logic [ 2:0] arprot;
  logic        rvalid;
  logic        rready;
  logic [31:0] rdata;
  logic        tx_out;

  axi_uart #(
      .BAUD_RATE(BAUD_RATE),
      .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
      .UART_ADDRESS(UART_ADDRESS)
  ) dut (
      .*
  );

  axi_uart_tb tb (.*);

  initial begin
    clk = 0;
    resetn = 0;
    resetn <= #1 1;
    forever begin
      #2 clk = ~clk;
    end
  end
endmodule

program axi_uart_tb #(
    parameter BAUD_RATE = 19600,
    parameter CLOCK_FREQUENCY = 100_000_000,
    parameter UART_ADDRESS = 32'h1000_0000
) (
    input clk,
    input resetn,

    // AXI4-lite slave interface
    output logic        awvalid,
    input               awready,
    output logic [31:0] awaddr,
    output       [ 2:0] awprot,

    output logic        wvalid,
    input               wready,
    output logic [31:0] wdata,
    output       [ 3:0] wstrb,

    input bvalid,
    output logic bready,

    output        arvalid,
    input         arready,
    output [31:0] araddr,
    output [ 2:0] arprot,

    input         rvalid,
    output        rready,
    input  [31:0] rdata,

    input tx_out
);
  initial begin
    wvalid  = 0;
    awvalid = 0;
    awaddr  = UART_ADDRESS;
    @(posedge clk);
    awvalid = 1;
    @(posedge awready);
    awvalid = 0;
    // TODO: check if the transmitted data correct?
    wdata   = 32'h0000_000f;
    @(posedge wready);
    wvalid = 1;
    @(posedge clk);
    wvalid = 0;
    bready = 1;
    @(posedge bvalid);
    @(posedge clk);
    bready = 0;
    repeat (2 * 4 * 32) @(posedge clk);
    $finish;
  end
endprogram
