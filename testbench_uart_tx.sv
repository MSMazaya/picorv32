module top_uart_tx_tb;
  localparam BITS = 4;
  localparam N_OVERSAMPLE = 2;
  localparam BAUD_RATE = 1;
  localparam CLOCK_FREQUENCY = 2;

  logic clk;
  logic resetn;
  logic load;
  logic baud_tick;
  logic [BITS-1:0] tx_din;
  logic tx_out;
  logic done;

  baud_generator #(
      .N_OVERSAMPLE(N_OVERSAMPLE),
      .BAUD_RATE(BAUD_RATE),
      .CLOCK_FREQUENCY(CLOCK_FREQUENCY)
  ) b_gen (
      .clk(clk),
      .resetn(resetn),
      .en(1'b1),
      .done(baud_tick)
  );

  uart_tx #(
      .N_OVERSAMPLE(N_OVERSAMPLE),
      .BITS(BITS)
  ) dut (
      .*
  );
  uart_tx_tb #(
      .N_OVERSAMPLE(N_OVERSAMPLE),
      .BITS(BITS)
  ) tb (
      .*
  );

  initial begin
    baud_tick = 0;
    clk = 0;
    resetn = 0;
    resetn <= #1 1;
    forever begin
      #2 clk = ~clk;
    end
  end
endmodule

program uart_tx_tb #(
    parameter N_OVERSAMPLE = 16,
    parameter BITS = 32
) (
    input clk,
    input resetn,
    output logic load,
    input baud_tick,
    output logic [31:0] tx_din,
    input tx_out,
    input done
);
  initial begin
    @(posedge clk);
    tx_din = 4'b0101;
    load   = 1;
    @(posedge clk);
    load = 0;
    @(posedge clk);
    repeat (4 * 32) @(posedge clk);
    $finish;
  end
endprogram
