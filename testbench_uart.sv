module top_uart_tb;
  localparam BAUD_RATE = 1;
  localparam CLOCK_FREQUENCY = 32;

  logic clk;
  logic resetn;
  logic [7:0] wr_data;
  logic wr_en;
  logic wr_done;
  logic wr_full;
  logic [7:0] rd_data;
  logic rd_en;
  logic rd_done;
  logic rd_empty;
  logic tx_out;

  uart #(
      .BAUD_RATE(BAUD_RATE),
      .CLOCK_FREQUENCY(CLOCK_FREQUENCY)
  ) dut (
      .*
  );

  uart_tb tb (.*);

  initial begin
    clk = 0;
    resetn = 0;
    resetn <= #1 1;
    forever begin
      #2 clk = ~clk;
    end
  end
endmodule

program uart_tb #(
    parameter N_OVERSAMPLE = 16,
    parameter BITS = 32
) (
    input clk,
    input resetn,

    // Write signals
    output logic [7:0] wr_data,
    output logic wr_en,
    input wr_done,
    input wr_full,

    // Read signals
    input [7:0] rd_data,
    output rd_en,
    input rd_done,
    input rd_empty,

    // Output signals
    input tx_out
);
  initial begin
    wr_en = 0;
    @(posedge clk);
    wr_en   = 1;
    wr_data = 8'b10010110;
    @(posedge clk);
    wr_data = 8'b10100101;
    repeat (1) @(posedge clk);
    wr_data = 8'b0;
    wr_en   = 0;
    repeat (2 * 4 * 32) @(posedge clk);
    $finish;
  end
endprogram
