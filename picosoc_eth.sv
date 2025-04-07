`define debug 1
`define RISCV_FORMAL 1

module picosoc_eth (
    input clk,
    input resetn,
    output uart_tx_out,
    output trap,
    //RAM Interface
    inout [15:0] ddr2_dq,
    inout [1:0] ddr2_dqs_n,
    inout [1:0] ddr2_dqs_p,
    output [12:0] ddr2_addr,
    output [2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output ddr2_ck_p,
    output ddr2_ck_n,
    output ddr2_cke,
    output ddr2_cs_n,
    output [1:0] ddr2_dm,
    output ddr2_odt
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
  wire [35:0] trace_data;

  localparam STACK_ADDRESS = 32'hFFFF_FFF0;

  wire cpu_clk, mem_clk;
  wire clk_locked;


  clk_wiz_0 instance_name (
      // Clock out ports
      .clk_out1(mem_clk),     // output clk_out1
      .clk_out2(cpu_clk),     // output clk_out2
      // Status and control signals
      .reset   (resetn),      // input reset
      .locked  (clk_locked),  // output locked
      // Clock in ports
      .clk_in1 (clk)          // input clk_in1
  );

  picorv32_axi #(
      .STACKADDR(STACK_ADDRESS),
      .COMPRESSED_ISA(1)
  ) soc_core (
      .clk(clk),
      .resetn(resetn & clk_locked),
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

  axi_bus #(
      .UART_ADDRESS  (32'h1000_0000),
      .MEMORY_ADDRESS(32'h0000_0000),
      .STACK_ADDRESS (STACK_ADDRESS)
  ) bus (
      .cpu_clk(cpu_clk),
      .mem_clk(mem_clk),
      .resetn(resetn & clk_locked),
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
      .uart_tx_out(uart_tx_out),
      .ddr2_addr (ddr2_addr),
      .ddr2_ba   (ddr2_ba),
      .ddr2_cas_n(ddr2_cas_n),
      .ddr2_ck_n (ddr2_ck_n),
      .ddr2_ck_p (ddr2_ck_p),
      .ddr2_cke  (ddr2_cke),
      .ddr2_ras_n(ddr2_ras_n),
      .ddr2_we_n (ddr2_we_n),
      .ddr2_dq   (ddr2_dq),
      .ddr2_dqs_n(ddr2_dqs_n),
      .ddr2_dqs_p(ddr2_dqs_p),
      .ddr2_cs_n (ddr2_cs_n),
      .ddr2_dm   (ddr2_dm),
      .ddr2_odt  (ddr2_odt)
  );

endmodule

module axi_bus #(
    parameter UART_ADDRESS   = 32'h1000_0000,
    parameter MEMORY_ADDRESS = 32'h0000_0000,
    parameter STACK_ADDRESS  = 32'hFFFF_FFFF
) (
    input         mem_axi_awvalid,
    output        mem_axi_awready,
    input  [31:0] mem_axi_awaddr,
    input  [ 2:0] mem_axi_awprot,

    input         mem_axi_wvalid,
    output        mem_axi_wready,
    input  [31:0] mem_axi_wdata,
    input  [ 3:0] mem_axi_wstrb,

    output mem_axi_bvalid,
    input  mem_axi_bready,

    input         mem_axi_arvalid,
    output        mem_axi_arready,
    input  [31:0] mem_axi_araddr,
    input  [ 2:0] mem_axi_arprot,

    output        mem_axi_rvalid,
    input         mem_axi_rready,
    output [31:0] mem_axi_rdata,

    input cpu_clk,
    input mem_clk,
    input resetn,

    output logic uart_tx_out,

    //RAM Interface
    inout [15:0] ddr2_dq,
    inout [1:0] ddr2_dqs_n,
    inout [1:0] ddr2_dqs_p,
    output [12:0] ddr2_addr,
    output [2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output ddr2_ck_p,
    output ddr2_ck_n,
    output ddr2_cke,
    output ddr2_cs_n,
    output [1:0] ddr2_dm,
    output ddr2_odt
);
  wire is_uart_w = (mem_axi_awaddr == UART_ADDRESS);
  wire is_stack_w = (mem_axi_awaddr >= (STACK_ADDRESS - 4096)) && (mem_axi_awaddr <= STACK_ADDRESS);
  wire is_mem_w = (!is_uart_w && !is_stack_w);

  wire is_uart_r = (mem_axi_araddr == UART_ADDRESS);
  wire is_stack_r = (mem_axi_araddr >= (STACK_ADDRESS - 4096)) && (mem_axi_araddr <= STACK_ADDRESS);
  wire is_mem_r = (!is_uart_r && !is_stack_r);

  logic axi_uart_awready, axi_uart_wready, axi_uart_bvalid;
  logic axi_uart_arready, axi_uart_rvalid;
  logic [31:0] axi_uart_rdata;

  logic axi_mem_awready, axi_mem_wready, axi_mem_bvalid;
  logic axi_mem_arready, axi_mem_rvalid;
  logic [31:0] axi_mem_rdata;

  logic axi_stack_awready, axi_stack_wready, axi_stack_bvalid;
  logic axi_stack_arready, axi_stack_rvalid;
  logic [31:0] axi_stack_rdata;

  axi_uart #(
      .BAUD_RATE(9600),
      .CLOCK_FREQUENCY(100_000_000),
      .UART_ADDRESS(UART_ADDRESS)
  ) uart (
      .clk(cpu_clk),
      .resetn(resetn),
      .awvalid(mem_axi_awvalid && is_uart_w),
      .awready(axi_uart_awready),
      .awaddr(mem_axi_awaddr),
      .awprot(mem_axi_awprot),
      .wvalid(mem_axi_wvalid && is_uart_w),
      .wready(axi_uart_wready),
      .wdata(mem_axi_wdata),
      .wstrb(mem_axi_wstrb),
      .bvalid(axi_uart_bvalid),
      .bready(mem_axi_bready),
      .arvalid(mem_axi_arvalid && is_uart_r),
      .arready(axi_uart_arready),
      .araddr(mem_axi_araddr),
      .arprot(mem_axi_arprot),
      .rvalid(axi_uart_rvalid),
      .rready(mem_axi_rready),
      .rdata(axi_uart_rdata),
      .tx_out(uart_tx_out)
  );

  axi_memory #(
      .START_ADDRESS(MEMORY_ADDRESS),
      .MEM_SIZE(4096)
  ) memory (
      .clk(cpu_clk),
      .resetn(resetn),
      .awvalid(mem_axi_awvalid && is_mem_w),
      .awready(axi_mem_awready),
      .awaddr(mem_axi_awaddr),
      .awprot(mem_axi_awprot),
      .wvalid(mem_axi_wvalid && is_mem_w),
      .wready(axi_mem_wready),
      .wdata(mem_axi_wdata),
      .wstrb(mem_axi_wstrb),
      .bvalid(axi_mem_bvalid),
      .bready(mem_axi_bready),
      .arvalid(mem_axi_arvalid && is_mem_r),
      .arready(axi_mem_arready),
      .araddr(mem_axi_araddr),
      .arprot(mem_axi_arprot),
      .rvalid(axi_mem_rvalid),
      .rready(mem_axi_rready),
      .rdata(axi_mem_rdata)
  );

  axi_memory #(
      .START_ADDRESS(STACK_ADDRESS - 4096),
      .MEM_SIZE(4096)
  ) stack_mem (
      .clk(cpu_clk),
      .resetn(resetn),
      .awvalid(mem_axi_awvalid && is_stack_w),
      .awready(axi_stack_awready),
      .awaddr(mem_axi_awaddr),
      .awprot(mem_axi_awprot),
      .wvalid(mem_axi_wvalid && is_stack_w),
      .wready(axi_stack_wready),
      .wdata(mem_axi_wdata),
      .wstrb(mem_axi_wstrb),
      .bvalid(axi_stack_bvalid),
      .bready(mem_axi_bready),
      .arvalid(mem_axi_arvalid && is_stack_r),
      .arready(axi_stack_arready),
      .araddr(mem_axi_araddr),
      .arprot(mem_axi_arprot),
      .rvalid(axi_stack_rvalid),
      .rready(mem_axi_rready),
      .rdata(axi_stack_rdata)
  );

  assign mem_axi_awready = is_uart_w  ? axi_uart_awready  :
                           is_stack_w ? axi_stack_awready : is_mem_w ? axi_mem_awready : 0;
  assign mem_axi_wready  = is_uart_w  ? axi_uart_wready  :
                           is_stack_w ? axi_stack_wready : is_mem_w ? axi_mem_wready : 0;
  assign mem_axi_bvalid  = is_uart_w  ? axi_uart_bvalid  :
                           is_stack_w ? axi_stack_bvalid : is_mem_w ? axi_mem_bvalid : 0;
  assign mem_axi_arready = is_uart_r  ? axi_uart_arready  :
                           is_stack_r ? axi_stack_arready : is_mem_r ? axi_mem_arready : 0;
  assign mem_axi_rvalid  = is_uart_r  ? axi_uart_rvalid  :
                           is_stack_r ? axi_stack_rvalid : is_mem_r ? axi_mem_rvalid : 0;
  assign mem_axi_rdata = is_uart_r ? axi_uart_rdata : is_stack_r ? axi_stack_rdata : is_mem_r ? axi_mem_rdata : 0;
endmodule

// https://github.com/ChrisPVille/mig_example/blob/5e74cdf126eac6381e97da03a6dd17c891f222e3/mig_example.srcs/sources_1/new/mem_example.v
module axi_ddr2 (
    input mem_clk,
    input resetn,

    //RAM Interface
    inout [15:0] ddr2_dq,
    inout [1:0] ddr2_dqs_n,
    inout [1:0] ddr2_dqs_p,
    output [12:0] ddr2_addr,
    output [2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output ddr2_ck_p,
    output ddr2_ck_n,
    output ddr2_cke,
    output ddr2_cs_n,
    output [1:0] ddr2_dm,
    output ddr2_odt,

    input  [ 3:0] s_axi_awid,
    input  [26:0] s_axi_awaddr,
    input  [ 7:0] s_axi_awlen,
    input  [ 2:0] s_axi_awsize,
    input  [ 1:0] s_axi_awburst,
    input  [ 0:0] s_axi_awlock,
    input  [ 3:0] s_axi_awcache,
    input  [ 2:0] s_axi_awprot,
    input  [ 3:0] s_axi_awqos,
    input         s_axi_awvalid,
    output        s_axi_awready,

    input  [31:0] s_axi_wdata,
    input  [ 3:0] s_axi_wstrb,
    input         s_axi_wlast,
    input         s_axi_wvalid,
    output        s_axi_wready,

    output [3:0] s_axi_bid,
    output [1:0] s_axi_bresp,
    output       s_axi_bvalid,
    input        s_axi_bready,

    input  [ 3:0] s_axi_arid,
    input  [26:0] s_axi_araddr,
    input  [ 7:0] s_axi_arlen,
    input  [ 2:0] s_axi_arsize,
    input  [ 1:0] s_axi_arburst,
    input  [ 0:0] s_axi_arlock,
    input  [ 3:0] s_axi_arcache,
    input  [ 2:0] s_axi_arprot,
    input  [ 3:0] s_axi_arqos,
    input         s_axi_arvalid,
    output        s_axi_arready,

    output [ 3:0] s_axi_rid,
    output [31:0] s_axi_rdata,
    output [ 1:0] s_axi_rresp,
    output        s_axi_rlast,
    output        s_axi_rvalid,
    input         s_axi_rready
);

  mig u_mig (
      // Memory interface ports
      .ddr2_addr (ddr2_addr),   // output [12:0]                       ddr2_addr
      .ddr2_ba   (ddr2_ba),     // output [2:0]                      ddr2_ba
      .ddr2_cas_n(ddr2_cas_n),  // output                                       ddr2_cas_n
      .ddr2_ck_n (ddr2_ck_n),   // output [0:0]                        ddr2_ck_n
      .ddr2_ck_p (ddr2_ck_p),   // output [0:0]                        ddr2_ck_p
      .ddr2_cke  (ddr2_cke),    // output [0:0]                       ddr2_cke
      .ddr2_ras_n(ddr2_ras_n),  // output                                       ddr2_ras_n
      .ddr2_we_n (ddr2_we_n),   // output                                       ddr2_we_n
      .ddr2_dq   (ddr2_dq),     // inout [15:0]                         ddr2_dq
      .ddr2_dqs_n(ddr2_dqs_n),  // inout [1:0]                        ddr2_dqs_n
      .ddr2_dqs_p(ddr2_dqs_p),  // inout [1:0]                        ddr2_dqs_p
      .ddr2_cs_n (ddr2_cs_n),   // output [0:0]           ddr2_cs_n
      .ddr2_dm   (ddr2_dm),     // output [1:0]                        ddr2_dm
      .ddr2_odt  (ddr2_odt),    // output [0:0]                       ddr2_odt

      // Application interface ports
      .ui_clk(ui_clk),  // output                                       ui_clk
      .ui_clk_sync_rst(ui_clk_sync_rst),  // output                                       ui_clk_sync_rst
      .mmcm_locked(mmcm_locked),  // 
      .aresetn(aresetn),  // 
      .app_sr_req(1'b0),  // input                                        app_sr_req
      .app_ref_req(1'b0),  // input                                        app_ref_req
      .app_zq_req(1'b0),  // input                                        app_zq_req
      .app_sr_active(),  // output                                       app_sr_active
      .app_ref_ack(),  // output                                       app_ref_ack
      .app_zq_ack(),  // output                                       app_zq_ack

      // Slave Interface Write Address Ports
      .s_axi_awid   (s_axi_awid),     // input  [3:0]                s_axi_awid
      .s_axi_awaddr (s_axi_awaddr),   // input  [26:0]              s_axi_awaddr
      .s_axi_awlen  (s_axi_awlen),    // input  [7:0]                                 s_axi_awlen
      .s_axi_awsize (s_axi_awsize),   // input  [2:0]                                 s_axi_awsize
      .s_axi_awburst(s_axi_awburst),  // input  [1:0]                                 s_axi_awburst
      .s_axi_awlock (s_axi_awlock),   // input  [0:0]                                 s_axi_awlock
      .s_axi_awcache(s_axi_awcache),  // input  [3:0]                                 s_axi_awcache
      .s_axi_awprot (s_axi_awprot),   // input  [2:0]                                 s_axi_awprot
      .s_axi_awqos  (s_axi_awqos),    // input  [3:0]                                 s_axi_awqos
      .s_axi_awvalid(s_axi_awvalid),  // input                                        s_axi_awvalid
      .s_axi_awready(s_axi_awready),  // output                                       s_axi_awready
      // Slave Interface Write Data Ports
      .s_axi_wdata  (s_axi_wdata),    // input  [31:0]              s_axi_wdata
      .s_axi_wstrb  (s_axi_wstrb),    // input  [3:0]            s_axi_wstrb
      .s_axi_wlast  (s_axi_wlast),    // input                                        s_axi_wlast
      .s_axi_wvalid (s_axi_wvalid),   // input                                        s_axi_wvalid
      .s_axi_wready (s_axi_wready),   // output                                       s_axi_wready
      // Slave Interface Write Response Ports
      .s_axi_bid    (s_axi_bid),      // output [3:0]                s_axi_bid
      .s_axi_bresp  (s_axi_bresp),    // output [1:0]                                 s_axi_bresp
      .s_axi_bvalid (s_axi_bvalid),   // output                                       s_axi_bvalid
      .s_axi_bready (s_axi_bready),   // input                                        s_axi_bready
      // Slave Interface Read Address Ports
      .s_axi_arid   (s_axi_arid),     // input  [3:0]                s_axi_arid
      .s_axi_araddr (s_axi_araddr),   // input  [26:0]              s_axi_araddr
      .s_axi_arlen  (s_axi_arlen),    // input  [7:0]                                 s_axi_arlen
      .s_axi_arsize (s_axi_arsize),   // input  [2:0]                                 s_axi_arsize
      .s_axi_arburst(s_axi_arburst),  // input  [1:0]                                 s_axi_arburst
      .s_axi_arlock (s_axi_arlock),   // input  [0:0]                                 s_axi_arlock
      .s_axi_arcache(s_axi_arcache),  // input  [3:0]                                 s_axi_arcache
      .s_axi_arprot (s_axi_arprot),   // input  [2:0]                                 s_axi_arprot
      .s_axi_arqos  (s_axi_arqos),    // input  [3:0]                                 s_axi_arqos
      .s_axi_arvalid(s_axi_arvalid),  // input                                        s_axi_arvalid
      .s_axi_arready(s_axi_arready),  // output                                       s_axi_arready
      // Slave Interface Read Data Ports
      .s_axi_rid    (s_axi_rid),      // output [3:0]                s_axi_rid
      .s_axi_rdata  (s_axi_rdata),    // output [31:0]              s_axi_rdata
      .s_axi_rresp  (s_axi_rresp),    // output [1:0]                                 s_axi_rresp
      .s_axi_rlast  (s_axi_rlast),    // output                                       s_axi_rlast
      .s_axi_rvalid (s_axi_rvalid),   // output                                       s_axi_rvalid
      .s_axi_rready (s_axi_rready),   // input                                        s_axi_rready
      // System Clock Ports
      .sys_clk_i    (sys_clk_i),
      // Reference Clock Ports
      .clk_ref_i    (clk_ref_i),
      .sys_rst      (sys_rst)         // input  sys_rst
  );
endmodule

module axi_memory #(
    parameter START_ADDRESS = 32'h0000_0000,
    parameter MEM_SIZE = 4096
) (
    input clk,
    input resetn,

    input               awvalid,
    output logic        awready,
    input        [31:0] awaddr,
    input        [ 2:0] awprot,

    input               wvalid,
    output logic        wready,
    input        [31:0] wdata,
    input        [ 3:0] wstrb,

    output logic bvalid,
    input        bready,

    input               arvalid,
    output logic        arready,
    input        [31:0] araddr,
    input        [ 2:0] arprot,

    output logic        rvalid,
    input               rready,
    output logic [31:0] rdata

);
  localparam END_ADDRESS = START_ADDRESS + MEM_SIZE;
  // FIXME: this will be used in stack too
  logic w_enable;
  ram #(
      .DEPTH(MEM_SIZE),
      .WIDTH(32)
  ) ram (
      .clk(clk),
      .r_data(rdata),
      .r_addr(araddr >> 2),
      .w_addr(awaddr >> 2),
      .we(w_enable),
      .w_data(w_data)
  );

  typedef enum bit [1:0] {
    IDLE,
    PUT_DATA,
    READ_DATA,
    RESPOND
  } state_t;
  state_t state, state_next;

  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) begin
      state <= IDLE;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;
    bvalid = 0;
    awready = 0;
    arready = 0;
    wready = 0;
    rvalid = 0;
    w_enable = 0;
    case (state)
      IDLE: begin
        if (awvalid & (awaddr >= START_ADDRESS) & (awaddr < END_ADDRESS)) begin
          awready = 1;
          state_next = PUT_DATA;
        end else if (arvalid) begin
          arready = 1;
          rvalid  = 1;
        end
      end
      PUT_DATA: begin
        wready   = 1;
        w_enable = 1;
        if (wvalid) begin
          state_next = RESPOND;
        end
      end
      READ_DATA: begin
        if (rready) begin
          state_next = IDLE;
        end
      end
      RESPOND: begin
        if (bready) begin
          bvalid = 1;
          state_next = IDLE;
        end
      end
    endcase
  end
endmodule

module ram #(
    parameter DEPTH = 4096,
    parameter WIDTH = 32
) (
    input clk,
    input we,
    input [$clog2(DEPTH + 1)-1:0] r_addr,
    input [$clog2(DEPTH + 1)-1:0] w_addr,
    input [WIDTH-1:0] w_data,
    output reg [WIDTH-1:0] r_data
);
  (* ram_style = "block" *) reg [WIDTH-1:0] mem[0:DEPTH-1];

  initial $readmemh("firmware.mem", mem, 0, DEPTH - 1);

  always_ff @(posedge clk) begin
    if (we) mem[w_addr] <= w_data;
  end
  assign r_data = mem[r_addr];  // Synchronous read
endmodule

module axi_uart #(
    parameter BAUD_RATE = 9600,
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

    input               arvalid,
    output logic        arready,
    input        [31:0] araddr,
    input        [ 2:0] arprot,

    output logic        rvalid,
    input               rready,
    output       [31:0] rdata,

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
    // TODO: implement these
    rvalid = 0;
    arready = 0;
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
    parameter BAUD_RATE = 9_600,
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
  localparam N_OVERSAMPLE = 2;
  baud_generator #(
      .BAUD_RATE(BAUD_RATE),
      .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
      .N_OVERSAMPLE(N_OVERSAMPLE)
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
      .N_OVERSAMPLE(N_OVERSAMPLE),
      .BITS(8)
  ) tx (
      .clk(clk),
      .resetn(resetn),
      .baud_tick(baud_tick),
      .load(~tx_fifo_empty),
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
    END,
    DELAY
  } state_t;
  state_t state_reg, state_next;
  logic tx_out_reg, tx_out_next;
  logic [BITS-1:0] din_reg, din_next;
  // For counting oversampling
  logic [$clog2(N_OVERSAMPLE+1)-1:0] tick_counter_reg, tick_counter_next;
  // For counting data sent
  logic [$clog2(BITS+1)-1:0] bit_counter_reg, bit_counter_next;

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
        state_next  = DELAY;
      end
      DELAY: begin
        tx_out_next = 1;
        state_next  = IDLE;
      end
    endcase
  end

  assign tx_ready = (state_reg == IDLE);
  assign tx_out   = tx_out_reg;
endmodule

module baud_generator #(
    parameter N_OVERSAMPLE = 16,
    parameter BAUD_RATE = 9600,
    parameter CLOCK_FREQUENCY = 100_000_000
) (
    input  clk,
    input  resetn,
    input  en,
    output done
);
  localparam DIVISOR = (CLOCK_FREQUENCY / (BAUD_RATE * N_OVERSAMPLE));
  logic [$clog2(DIVISOR + 1)-1:0] counter_reg, counter_next;

  logic en_sync_1, en_sync_2;
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      en_sync_1 <= 0;
      en_sync_2 <= 0;
    end else begin
      en_sync_1 <= en;
      en_sync_2 <= en_sync_1;
    end
  end

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) counter_reg <= 0;
    else counter_reg <= counter_next;
  end

  always_comb begin
    counter_next = counter_reg;
    if (done) counter_next = 0;
    else if (en_sync_2) counter_next = counter_reg + 1'b1;
  end

  assign done = (counter_reg == DIVISOR - 1);
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
  logic [$clog2(BITS + 1):0] counter, counter_next;
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

