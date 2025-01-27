module top_baud_generator_tb;
  reg clk, resetn, en, done;

  baud_generator #(
      .BAUD_RATE(10),
      .CLOCK_FREQUENCY(100)
  ) dut (
      .*
  );

  baud_generator_tb tb (.*);

  initial begin
    clk = 0;
    resetn = 0;
    resetn <= #1 1;
    en = 0;
    en <= #1 1;
    repeat (400) #2 clk = ~clk;
  end
endmodule

program baud_generator_tb (
    output clk,
    output resetn,
    output logic en,
    input done
);
  initial begin
    repeat (400) @(posedge clk);
    en = 0;
    $finish;
  end
endprogram
