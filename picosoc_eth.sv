module picosoc_eth (
    input clk,
    input resetn
);

  // AXI4-lite master memory interface
  wire        mem_axi_awvalid;
  wire        mem_axi_awready;
  wire [31:0] mem_axi_awaddr;
  wire [ 2:0] mem_axi_awprot;

  wire        mem_axi_wvalid;
  wire        mem_axi_wready;
  wire [31:0] mem_axi_wdata;
  wire [ 3:0] mem_axi_wstrb;

  wire        mem_axi_bvalid;
  wire        mem_axi_bready;

  wire        mem_axi_arvalid;
  wire        mem_axi_arready;
  wire [31:0] mem_axi_araddr;
  wire [ 2:0] mem_axi_arprot;

  wire        mem_axi_rvalid;
  wire        mem_axi_rready;
  wire [31:0] mem_axi_rdata;

  // Look-Ahead Interface
  wire        mem_la_read;
  wire        mem_la_write;
  wire [31:0] mem_la_addr;
  wire [31:0] mem_la_wdata;
  wire [ 3:0] mem_la_wstrb;

  // Pico Co-Processor Interface (PCPI)
  wire        pcpi_valid;
  wire [31:0] pcpi_insn;
  wire [31:0] pcpi_rs1;
  wire [31:0] pcpi_rs2;
  wire        pcpi_wr;
  wire [31:0] pcpi_rd;
  wire        pcpi_wait;
  wire        pcpi_ready;

  // IRQ Interface
  wire [31:0] irq;
  wire [31:0] eoi;

  // Trace Interface
  wire        trace_valid;
  wire [35:0] trace_dat;

  picorv32_axi soc_core (
      .clk(clk),
      .resetn(resetn),
      .trap(trap),
      .mem_axi_awvalid(mem_axi_awvalid),
      .mem_axi_awready(mem_axi_awready),
      .mem_axi_awaddr(mem_axi_awaddr),
      .mem_axi_awprot(mem_axi_awprot),
      .mem_axi_wvalid(mem_axi_wvalid),
      .mem_axi_wready(mem_axi_wready),
      .mem_axi_wdata(mem_axi_wdata),
      .mem_axi_wstrb(mem_axi_wstrb),
      .mem_axi_bvalid(mem_axi_bvalid),
      .mem_axi_bready(mem_axi_bready),
      .mem_axi_arvalid(mem_axi_arvalid),
      .mem_axi_arready(mem_axi_arready),
      .mem_axi_araddr(mem_axi_araddr),
      .mem_axi_arprot(mem_axi_arprot),
      .mem_axi_rvalid(mem_axi_rvalid),
      .mem_axi_rready(mem_axi_rready),
      .mem_axi_rdata(mem_axi_rdata),
      .pcpi_valid(pcpi_valid),
      .pcpi_insn(pcpi_insn),
      .pcpi_rs1(pcpi_rs1),
      .pcpi_rs2(pcpi_rs2),
      .pcpi_wr(pcpi_wr),
      .pcpi_rd(pcpi_rd),
      .pcpi_wait(pcpi_wait),
      .pcpi_ready(pcpi_ready),
      .irq(irq),
      .eoi(eoi),
      .trace_valid(trace_valid),
      .trace_data(trace_data)
  );
endmodule

module axi_bus (
    input mem_valid,
    input mem_instr,
    input mem_ready,

    input [31:0] mem_addr,
    input [31:0] mem_wdata,
    input [ 3:0] mem_wstrb,
    input [31:0] mem_rdata
);
endmodule

module axi_uart #(
    parameter BAUD_RATE = 19600,
    parameter CLOCK_FREQUENCY = 100_000_000,
    parameter UART_ADDRESS = 32'h1000_0000
) (
    input clk,
    input resetn,

    // AXI4-lite slave interface
    input               awvalid,
    output logic        awready,
    input        [31:0] awaddr,
    input        [ 2:0] awprot,

    input               wvalid,
    output logic        wready,
    input        [31:0] wdata,
    input        [ 3:0] wstrb,

    output logic bvalid,
    input bready,

    input         arvalid,
    output        arready,
    input  [31:0] araddr,
    input  [ 2:0] arprot,

    output        rvalid,
    input         rready,
    output [31:0] rdata,

    output tx_out
);
  // Component signals
  logic awready_next, wready_next;
  logic is_wadrr_uart;
  assign is_wadrr_uart = awaddr == UART_ADDRESS;
  logic response_buf;

  // State signals
  typedef enum bit [1:0] {
    IDLE,
    PUT_DATA,
    RESPOND
  } state_t;
  state_t state, state_next;

  // UART components & signals
  // Input
  logic uart_wr_en, uart_wr_en_next;
  // Output
  logic uart_wr_done, uart_wr_full;
  uart #(
      .BAUD_RATE(BAUD_RATE),
      .CLOCK_FREQUENCY(CLOCK_FREQUENCY)
  ) uart (
      .clk(clk),
      .resetn(resetn),

      // Write signals
      .wr_data(wdata[7:0]),
      .wr_en  (uart_wr_en),
      .wr_done(uart_wr_done),
      .wr_full(uart_wr_full),

      // Read signals
      .rd_data(),
      .rd_en(),
      .rd_done(),
      .rd_empty(),

      .tx_out(tx_out)
  );

  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) begin
      state <= IDLE;
      awready <= 0;
      wready <= 0;
      uart_wr_en <= 0;
    end else begin
      state <= state_next;
      awready <= awready_next;
      wready <= wready_next;
      uart_wr_en <= uart_wr_en_next;
    end
  end

  always_comb begin
    state_next = state;
    awready_next = 0;
    uart_wr_en_next = 0;
    wready_next = 0;
    bvalid = 0;
    case (state)
      IDLE: begin
        response_buf = 0;
        if (is_wadrr_uart & awvalid) begin
          state_next   = PUT_DATA;
          awready_next = 1;
        end
      end
      PUT_DATA: begin
        response_buf = 0;
        if (~uart_wr_full) begin
          wready_next = 1;
          uart_wr_en_next = 1;
          // Assuming AXI4-lite
          // Therefore 1 data at a time
          state_next = RESPOND;
        end
      end
      RESPOND: begin
        if (uart_wr_done) response_buf = 1;
        if (bready) begin
          bvalid = response_buf;
          if (bvalid) state_next = IDLE;
        end
      end
    endcase
  end
endmodule

module uart #(
    parameter BAUD_RATE = 19_600,
    parameter CLOCK_FREQUENCY = 100_000_000
) (
    input clk,
    input resetn,

    // Write signals
    input [7:0] wr_data,
    input wr_en,
    output wr_done,
    output wr_full,

    // Read signals
    output [7:0] rd_data,
    input rd_en,
    output rd_done,
    output rd_empty,

    // Output signals
    output tx_out
);
  wire baud_tick;
  baud_generator #(
      .BAUD_RATE(BAUD_RATE),
      .CLOCK_FREQUENCY(CLOCK_FREQUENCY)
  ) b_gen (
      .clk(clk),
      .resetn(resetn),
      // TODO: make this more efficient
      .en(1'b1),
      .done(baud_tick)
  );

  logic tx_ready, tx_fifo_empty, rd_valid;
  logic [7:0] tx_din;
  fifo_generator_0 tx_fifo (
      .clk(clk),  // input wire clk
      .srst(~resetn),  // input wire srst
      .din(wr_data),  // input wire [7 : 0] din
      .wr_en(wr_en),  // input wire wr_en
      .rd_en(tx_ready),  // input wire rd_en
      .dout(tx_din),  // output wire [7 : 0] dout
      .full(wr_full),  // output wire full
      .empty(tx_fifo_empty),  // output wire empty
      .wr_ack(wr_done),  // output wire wr_ack
      .valid(rd_valid)  // output wire valid
  );

  uart_tx #(
      .N_OVERSAMPLE(4),
      .BITS(8)
  ) tx (
      .clk(clk),
      .resetn(resetn),
      .baud_tick(baud_tick),
      .load(rd_valid),
      .tx_din(tx_din),
      .tx_out(tx_out),
      .tx_ready(tx_ready)
  );
endmodule

module uart_tx #(
    parameter N_OVERSAMPLE = 16,
    parameter BITS = 8
) (
    input clk,
    input resetn,
    input baud_tick,
    input load,
    input [BITS-1:0] tx_din,
    output logic tx_out,
    output logic tx_ready
);
  typedef enum bit [2:0] {
    IDLE,
    START,
    SYNC_TICK,
    SEND_DATA,
    END
  } state_t;
  state_t state_reg, state_next;
  logic tx_out_reg, tx_out_next;
  logic [BITS-1:0] din_reg, din_next;
  // For counting oversampling
  logic [$clog2(N_OVERSAMPLE)-1:0] tick_counter_reg, tick_counter_next;
  // For counting data sent
  logic [$clog2(BITS)-1:0] bit_counter_reg, bit_counter_next;

  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) begin
      state_reg <= IDLE;
      tx_out_reg <= 0;
      bit_counter_reg <= 0;
      tick_counter_reg <= 0;
      din_reg <= 0;
    end else begin
      state_reg <= state_next;
      tx_out_reg <= tx_out_next;
      bit_counter_reg <= bit_counter_next;
      tick_counter_reg <= tick_counter_next;
      din_reg <= din_next;
    end
  end

  always_comb begin
    state_next = state_reg;
    tx_out_next = tx_out_reg;
    bit_counter_next = bit_counter_reg;
    tick_counter_next = tick_counter_reg;
    din_next = din_reg;
    case (state_reg)
      IDLE: begin
        tx_out_next = 1;
        if (load) begin
          din_next   = tx_din;
          state_next = SYNC_TICK;
        end
      end
      SYNC_TICK: begin
        if (baud_tick) state_next = START;
      end
      START: begin
        tx_out_next = 0;
        if (baud_tick) begin
          if (tick_counter_reg == N_OVERSAMPLE - 1) begin
            tick_counter_next = 0;
            state_next = SEND_DATA;
          end else begin
            tick_counter_next = tick_counter_reg + 1;
          end
        end
      end
      SEND_DATA: begin
        tx_out_next = din_reg[0];
        if (baud_tick) begin
          if (tick_counter_reg == N_OVERSAMPLE - 1) begin
            tick_counter_next = 0;
            din_next = {1'b0, din_reg[BITS-1:1]};
            if (bit_counter_reg == BITS - 1) begin
              bit_counter_next = 0;
              state_next = END;
            end else begin
              bit_counter_next = bit_counter_reg + 1;
            end
          end else begin
            tick_counter_next = tick_counter_reg + 1;
          end
        end
      end
      END: begin
        tx_out_next = 1;
        state_next  = IDLE;
      end
    endcase
  end

  assign tx_ready = (state_next == IDLE);
  assign tx_out   = tx_out_reg;
endmodule

module baud_generator #(
    parameter N_OVERSAMPLE = 16,
    parameter BAUD_RATE = 19_600,
    parameter CLOCK_FREQUENCY = 100_000_000
) (
    input clk,
    input resetn,
    input en,

    output done
);
  // Oversampling by 16 times
  localparam DIVISOR = (CLOCK_FREQUENCY / (BAUD_RATE * N_OVERSAMPLE));
  logic [$clog2(DIVISOR)-1:0] counter_reg, counter_next;

  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) counter_reg <= 0;
    else begin
      counter_reg <= counter_next;
    end
  end

  always_comb begin
    counter_next = counter_reg;
    if (done) counter_next = 0;
    else if (en) counter_next = counter_reg + 1'b1;
  end

  assign done = counter_reg == DIVISOR - 1;
endmodule

module uart_shift_register #(
    parameter BITS = 32
) (
    input clk,
    input resetn,
    input load,
    input tick,

    input [BITS-1:0] din,
    output out,
    output done
);
  logic [BITS-1:0] Q, Q_next;

  // Shift register logic
  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) Q <= 0;
    else begin
      Q <= Q_next;
    end
  end
  always_comb begin
    if (load) Q_next = din;
    else if (tick) Q_next = Q << 1;
    else Q_next = Q;
  end

  assign out = Q[BITS-1];

  // Counter for `done` signal
  logic [$clog2(BITS):0] counter, counter_next;
  enum bit {
    IDLE,
    COUNTING
  } state_t;
  logic state, next_state;

  // Counter state transition
  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) state <= IDLE;
    else begin
      state <= next_state;
    end
  end
  always_comb begin
    if (done) next_state = IDLE;
    else if (load) next_state = COUNTING;
    else next_state = state;
  end

  // Counter logic
  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) counter <= 0;
    else begin
      counter <= counter_next;
    end
  end
  always_comb begin
    if (done) counter_next = 0;
    else begin
      case (state)
        IDLE: counter_next = 0;
        COUNTING: begin
          if (tick) counter_next = counter + 1'b1;
          else counter_next = counter;
        end
      endcase
    end
  end

  assign done = counter == BITS;
endmodule

`ifndef PICORV32_REGS
`define PICORV32_REGS picosoc_regs
`endif

`ifndef PICOSOC_MEM
`define PICOSOC_MEM picosoc_mem
`endif

module picosoc_regs (
    input clk,
    wen,
    input [5:0] waddr,
    input [5:0] raddr1,
    input [5:0] raddr2,
    input [31:0] wdata,
    output [31:0] rdata1,
    output [31:0] rdata2
);
  reg [31:0] regs[0:31];

  always @(posedge clk) if (wen) regs[waddr[4:0]] <= wdata;

  assign rdata1 = regs[raddr1[4:0]];
  assign rdata2 = regs[raddr2[4:0]];
endmodule

module picosoc_mem #(
    parameter integer WORDS = 256
) (
    input clk,
    input [3:0] wen,
    input [21:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata
);
  reg [31:0] mem[0:WORDS-1];

  always @(posedge clk) begin
    rdata <= mem[addr];
    if (wen[0]) mem[addr][7:0] <= wdata[7:0];
    if (wen[1]) mem[addr][15:8] <= wdata[15:8];
    if (wen[2]) mem[addr][23:16] <= wdata[23:16];
    if (wen[3]) mem[addr][31:24] <= wdata[31:24];
  end
endmodule

