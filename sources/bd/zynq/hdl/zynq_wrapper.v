//Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2017.4.1 (win64) Build 2117270 Tue Jan 30 15:32:00 MST 2018
//Date        : Fri Jan  3 15:05:35 2020
//Host        : YDC-LAPTOP running 64-bit major release  (build 9200)
//Command     : generate_target zynq_wrapper.bd
//Design      : zynq_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module zynq_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIFO_READ_0_empty,
    FIFO_READ_0_rd_data,
    FIFO_READ_0_rd_en,
    FIFO_READ_1_empty,
    FIFO_READ_1_rd_data,
    FIFO_READ_1_rd_en,
    FIFO_WRITE_0_full,
    FIFO_WRITE_0_wr_data,
    FIFO_WRITE_0_wr_en,
    FIFO_WRITE_1_full,
    FIFO_WRITE_1_wr_data,
    FIFO_WRITE_1_wr_en,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    PL_TO_PS_0,
    PL_TO_PS_1,
    PL_TO_PS_2,
    PS_TO_PL_0,
    S_AXI_HP0_0_araddr,
    S_AXI_HP0_0_arburst,
    S_AXI_HP0_0_arcache,
    S_AXI_HP0_0_arid,
    S_AXI_HP0_0_arlen,
    S_AXI_HP0_0_arlock,
    S_AXI_HP0_0_arprot,
    S_AXI_HP0_0_arqos,
    S_AXI_HP0_0_arready,
    S_AXI_HP0_0_arsize,
    S_AXI_HP0_0_arvalid,
    S_AXI_HP0_0_awaddr,
    S_AXI_HP0_0_awburst,
    S_AXI_HP0_0_awcache,
    S_AXI_HP0_0_awid,
    S_AXI_HP0_0_awlen,
    S_AXI_HP0_0_awlock,
    S_AXI_HP0_0_awprot,
    S_AXI_HP0_0_awqos,
    S_AXI_HP0_0_awready,
    S_AXI_HP0_0_awsize,
    S_AXI_HP0_0_awvalid,
    S_AXI_HP0_0_bid,
    S_AXI_HP0_0_bready,
    S_AXI_HP0_0_bresp,
    S_AXI_HP0_0_bvalid,
    S_AXI_HP0_0_rdata,
    S_AXI_HP0_0_rid,
    S_AXI_HP0_0_rlast,
    S_AXI_HP0_0_rready,
    S_AXI_HP0_0_rresp,
    S_AXI_HP0_0_rvalid,
    S_AXI_HP0_0_wdata,
    S_AXI_HP0_0_wid,
    S_AXI_HP0_0_wlast,
    S_AXI_HP0_0_wready,
    S_AXI_HP0_0_wstrb,
    S_AXI_HP0_0_wvalid,
    S_AXI_HP1_0_araddr,
    S_AXI_HP1_0_arburst,
    S_AXI_HP1_0_arcache,
    S_AXI_HP1_0_arid,
    S_AXI_HP1_0_arlen,
    S_AXI_HP1_0_arlock,
    S_AXI_HP1_0_arprot,
    S_AXI_HP1_0_arqos,
    S_AXI_HP1_0_arready,
    S_AXI_HP1_0_arsize,
    S_AXI_HP1_0_arvalid,
    S_AXI_HP1_0_awaddr,
    S_AXI_HP1_0_awburst,
    S_AXI_HP1_0_awcache,
    S_AXI_HP1_0_awid,
    S_AXI_HP1_0_awlen,
    S_AXI_HP1_0_awlock,
    S_AXI_HP1_0_awprot,
    S_AXI_HP1_0_awqos,
    S_AXI_HP1_0_awready,
    S_AXI_HP1_0_awsize,
    S_AXI_HP1_0_awvalid,
    S_AXI_HP1_0_bid,
    S_AXI_HP1_0_bready,
    S_AXI_HP1_0_bresp,
    S_AXI_HP1_0_bvalid,
    S_AXI_HP1_0_rdata,
    S_AXI_HP1_0_rid,
    S_AXI_HP1_0_rlast,
    S_AXI_HP1_0_rready,
    S_AXI_HP1_0_rresp,
    S_AXI_HP1_0_rvalid,
    S_AXI_HP1_0_wdata,
    S_AXI_HP1_0_wid,
    S_AXI_HP1_0_wlast,
    S_AXI_HP1_0_wready,
    S_AXI_HP1_0_wstrb,
    S_AXI_HP1_0_wvalid,
    aux_reset_in_0,
    dcm_locked_0,
    fifo_reset,
    fifo_reset_1,
    logic_clk,
    logic_clk_pll_locked,
    periph_reset,
    pixel_clk,
    pixel_clk_pll_locked,
    pll_resets,
    ref_clk,
    ref_clk_pll_locked,
    resetn,
    valid_0,
    valid_1,
    wr_clk_0,
    wr_clk_1);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  output FIFO_READ_0_empty;
  output [63:0]FIFO_READ_0_rd_data;
  input FIFO_READ_0_rd_en;
  output FIFO_READ_1_empty;
  output [63:0]FIFO_READ_1_rd_data;
  input FIFO_READ_1_rd_en;
  output FIFO_WRITE_0_full;
  input [63:0]FIFO_WRITE_0_wr_data;
  input FIFO_WRITE_0_wr_en;
  output FIFO_WRITE_1_full;
  input [63:0]FIFO_WRITE_1_wr_data;
  input FIFO_WRITE_1_wr_en;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  input [3:0]PL_TO_PS_0;
  input [31:0]PL_TO_PS_1;
  input [31:0]PL_TO_PS_2;
  output [1:0]PS_TO_PL_0;
  input [31:0]S_AXI_HP0_0_araddr;
  input [1:0]S_AXI_HP0_0_arburst;
  input [3:0]S_AXI_HP0_0_arcache;
  input [5:0]S_AXI_HP0_0_arid;
  input [3:0]S_AXI_HP0_0_arlen;
  input [1:0]S_AXI_HP0_0_arlock;
  input [2:0]S_AXI_HP0_0_arprot;
  input [3:0]S_AXI_HP0_0_arqos;
  output S_AXI_HP0_0_arready;
  input [2:0]S_AXI_HP0_0_arsize;
  input S_AXI_HP0_0_arvalid;
  input [31:0]S_AXI_HP0_0_awaddr;
  input [1:0]S_AXI_HP0_0_awburst;
  input [3:0]S_AXI_HP0_0_awcache;
  input [5:0]S_AXI_HP0_0_awid;
  input [3:0]S_AXI_HP0_0_awlen;
  input [1:0]S_AXI_HP0_0_awlock;
  input [2:0]S_AXI_HP0_0_awprot;
  input [3:0]S_AXI_HP0_0_awqos;
  output S_AXI_HP0_0_awready;
  input [2:0]S_AXI_HP0_0_awsize;
  input S_AXI_HP0_0_awvalid;
  output [5:0]S_AXI_HP0_0_bid;
  input S_AXI_HP0_0_bready;
  output [1:0]S_AXI_HP0_0_bresp;
  output S_AXI_HP0_0_bvalid;
  output [63:0]S_AXI_HP0_0_rdata;
  output [5:0]S_AXI_HP0_0_rid;
  output S_AXI_HP0_0_rlast;
  input S_AXI_HP0_0_rready;
  output [1:0]S_AXI_HP0_0_rresp;
  output S_AXI_HP0_0_rvalid;
  input [63:0]S_AXI_HP0_0_wdata;
  input [5:0]S_AXI_HP0_0_wid;
  input S_AXI_HP0_0_wlast;
  output S_AXI_HP0_0_wready;
  input [7:0]S_AXI_HP0_0_wstrb;
  input S_AXI_HP0_0_wvalid;
  input [31:0]S_AXI_HP1_0_araddr;
  input [1:0]S_AXI_HP1_0_arburst;
  input [3:0]S_AXI_HP1_0_arcache;
  input [5:0]S_AXI_HP1_0_arid;
  input [3:0]S_AXI_HP1_0_arlen;
  input [1:0]S_AXI_HP1_0_arlock;
  input [2:0]S_AXI_HP1_0_arprot;
  input [3:0]S_AXI_HP1_0_arqos;
  output S_AXI_HP1_0_arready;
  input [2:0]S_AXI_HP1_0_arsize;
  input S_AXI_HP1_0_arvalid;
  input [31:0]S_AXI_HP1_0_awaddr;
  input [1:0]S_AXI_HP1_0_awburst;
  input [3:0]S_AXI_HP1_0_awcache;
  input [5:0]S_AXI_HP1_0_awid;
  input [3:0]S_AXI_HP1_0_awlen;
  input [1:0]S_AXI_HP1_0_awlock;
  input [2:0]S_AXI_HP1_0_awprot;
  input [3:0]S_AXI_HP1_0_awqos;
  output S_AXI_HP1_0_awready;
  input [2:0]S_AXI_HP1_0_awsize;
  input S_AXI_HP1_0_awvalid;
  output [5:0]S_AXI_HP1_0_bid;
  input S_AXI_HP1_0_bready;
  output [1:0]S_AXI_HP1_0_bresp;
  output S_AXI_HP1_0_bvalid;
  output [63:0]S_AXI_HP1_0_rdata;
  output [5:0]S_AXI_HP1_0_rid;
  output S_AXI_HP1_0_rlast;
  input S_AXI_HP1_0_rready;
  output [1:0]S_AXI_HP1_0_rresp;
  output S_AXI_HP1_0_rvalid;
  input [63:0]S_AXI_HP1_0_wdata;
  input [5:0]S_AXI_HP1_0_wid;
  input S_AXI_HP1_0_wlast;
  output S_AXI_HP1_0_wready;
  input [7:0]S_AXI_HP1_0_wstrb;
  input S_AXI_HP1_0_wvalid;
  input aux_reset_in_0;
  input dcm_locked_0;
  input fifo_reset;
  input fifo_reset_1;
  output logic_clk;
  output logic_clk_pll_locked;
  output [0:0]periph_reset;
  output pixel_clk;
  output pixel_clk_pll_locked;
  input pll_resets;
  output ref_clk;
  output ref_clk_pll_locked;
  output resetn;
  output valid_0;
  output valid_1;
  input wr_clk_0;
  input wr_clk_1;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIFO_READ_0_empty;
  wire [63:0]FIFO_READ_0_rd_data;
  wire FIFO_READ_0_rd_en;
  wire FIFO_READ_1_empty;
  wire [63:0]FIFO_READ_1_rd_data;
  wire FIFO_READ_1_rd_en;
  wire FIFO_WRITE_0_full;
  wire [63:0]FIFO_WRITE_0_wr_data;
  wire FIFO_WRITE_0_wr_en;
  wire FIFO_WRITE_1_full;
  wire [63:0]FIFO_WRITE_1_wr_data;
  wire FIFO_WRITE_1_wr_en;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [3:0]PL_TO_PS_0;
  wire [31:0]PL_TO_PS_1;
  wire [31:0]PL_TO_PS_2;
  wire [1:0]PS_TO_PL_0;
  wire [31:0]S_AXI_HP0_0_araddr;
  wire [1:0]S_AXI_HP0_0_arburst;
  wire [3:0]S_AXI_HP0_0_arcache;
  wire [5:0]S_AXI_HP0_0_arid;
  wire [3:0]S_AXI_HP0_0_arlen;
  wire [1:0]S_AXI_HP0_0_arlock;
  wire [2:0]S_AXI_HP0_0_arprot;
  wire [3:0]S_AXI_HP0_0_arqos;
  wire S_AXI_HP0_0_arready;
  wire [2:0]S_AXI_HP0_0_arsize;
  wire S_AXI_HP0_0_arvalid;
  wire [31:0]S_AXI_HP0_0_awaddr;
  wire [1:0]S_AXI_HP0_0_awburst;
  wire [3:0]S_AXI_HP0_0_awcache;
  wire [5:0]S_AXI_HP0_0_awid;
  wire [3:0]S_AXI_HP0_0_awlen;
  wire [1:0]S_AXI_HP0_0_awlock;
  wire [2:0]S_AXI_HP0_0_awprot;
  wire [3:0]S_AXI_HP0_0_awqos;
  wire S_AXI_HP0_0_awready;
  wire [2:0]S_AXI_HP0_0_awsize;
  wire S_AXI_HP0_0_awvalid;
  wire [5:0]S_AXI_HP0_0_bid;
  wire S_AXI_HP0_0_bready;
  wire [1:0]S_AXI_HP0_0_bresp;
  wire S_AXI_HP0_0_bvalid;
  wire [63:0]S_AXI_HP0_0_rdata;
  wire [5:0]S_AXI_HP0_0_rid;
  wire S_AXI_HP0_0_rlast;
  wire S_AXI_HP0_0_rready;
  wire [1:0]S_AXI_HP0_0_rresp;
  wire S_AXI_HP0_0_rvalid;
  wire [63:0]S_AXI_HP0_0_wdata;
  wire [5:0]S_AXI_HP0_0_wid;
  wire S_AXI_HP0_0_wlast;
  wire S_AXI_HP0_0_wready;
  wire [7:0]S_AXI_HP0_0_wstrb;
  wire S_AXI_HP0_0_wvalid;
  wire [31:0]S_AXI_HP1_0_araddr;
  wire [1:0]S_AXI_HP1_0_arburst;
  wire [3:0]S_AXI_HP1_0_arcache;
  wire [5:0]S_AXI_HP1_0_arid;
  wire [3:0]S_AXI_HP1_0_arlen;
  wire [1:0]S_AXI_HP1_0_arlock;
  wire [2:0]S_AXI_HP1_0_arprot;
  wire [3:0]S_AXI_HP1_0_arqos;
  wire S_AXI_HP1_0_arready;
  wire [2:0]S_AXI_HP1_0_arsize;
  wire S_AXI_HP1_0_arvalid;
  wire [31:0]S_AXI_HP1_0_awaddr;
  wire [1:0]S_AXI_HP1_0_awburst;
  wire [3:0]S_AXI_HP1_0_awcache;
  wire [5:0]S_AXI_HP1_0_awid;
  wire [3:0]S_AXI_HP1_0_awlen;
  wire [1:0]S_AXI_HP1_0_awlock;
  wire [2:0]S_AXI_HP1_0_awprot;
  wire [3:0]S_AXI_HP1_0_awqos;
  wire S_AXI_HP1_0_awready;
  wire [2:0]S_AXI_HP1_0_awsize;
  wire S_AXI_HP1_0_awvalid;
  wire [5:0]S_AXI_HP1_0_bid;
  wire S_AXI_HP1_0_bready;
  wire [1:0]S_AXI_HP1_0_bresp;
  wire S_AXI_HP1_0_bvalid;
  wire [63:0]S_AXI_HP1_0_rdata;
  wire [5:0]S_AXI_HP1_0_rid;
  wire S_AXI_HP1_0_rlast;
  wire S_AXI_HP1_0_rready;
  wire [1:0]S_AXI_HP1_0_rresp;
  wire S_AXI_HP1_0_rvalid;
  wire [63:0]S_AXI_HP1_0_wdata;
  wire [5:0]S_AXI_HP1_0_wid;
  wire S_AXI_HP1_0_wlast;
  wire S_AXI_HP1_0_wready;
  wire [7:0]S_AXI_HP1_0_wstrb;
  wire S_AXI_HP1_0_wvalid;
  wire aux_reset_in_0;
  wire dcm_locked_0;
  wire fifo_reset;
  wire fifo_reset_1;
  wire logic_clk;
  wire logic_clk_pll_locked;
  wire [0:0]periph_reset;
  wire pixel_clk;
  wire pixel_clk_pll_locked;
  wire pll_resets;
  wire ref_clk;
  wire ref_clk_pll_locked;
  wire resetn;
  wire valid_0;
  wire valid_1;
  wire wr_clk_0;
  wire wr_clk_1;

  zynq zynq_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIFO_READ_0_empty(FIFO_READ_0_empty),
        .FIFO_READ_0_rd_data(FIFO_READ_0_rd_data),
        .FIFO_READ_0_rd_en(FIFO_READ_0_rd_en),
        .FIFO_READ_1_empty(FIFO_READ_1_empty),
        .FIFO_READ_1_rd_data(FIFO_READ_1_rd_data),
        .FIFO_READ_1_rd_en(FIFO_READ_1_rd_en),
        .FIFO_WRITE_0_full(FIFO_WRITE_0_full),
        .FIFO_WRITE_0_wr_data(FIFO_WRITE_0_wr_data),
        .FIFO_WRITE_0_wr_en(FIFO_WRITE_0_wr_en),
        .FIFO_WRITE_1_full(FIFO_WRITE_1_full),
        .FIFO_WRITE_1_wr_data(FIFO_WRITE_1_wr_data),
        .FIFO_WRITE_1_wr_en(FIFO_WRITE_1_wr_en),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .PL_TO_PS_0(PL_TO_PS_0),
        .PL_TO_PS_1(PL_TO_PS_1),
        .PL_TO_PS_2(PL_TO_PS_2),
        .PS_TO_PL_0(PS_TO_PL_0),
        .S_AXI_HP0_0_araddr(S_AXI_HP0_0_araddr),
        .S_AXI_HP0_0_arburst(S_AXI_HP0_0_arburst),
        .S_AXI_HP0_0_arcache(S_AXI_HP0_0_arcache),
        .S_AXI_HP0_0_arid(S_AXI_HP0_0_arid),
        .S_AXI_HP0_0_arlen(S_AXI_HP0_0_arlen),
        .S_AXI_HP0_0_arlock(S_AXI_HP0_0_arlock),
        .S_AXI_HP0_0_arprot(S_AXI_HP0_0_arprot),
        .S_AXI_HP0_0_arqos(S_AXI_HP0_0_arqos),
        .S_AXI_HP0_0_arready(S_AXI_HP0_0_arready),
        .S_AXI_HP0_0_arsize(S_AXI_HP0_0_arsize),
        .S_AXI_HP0_0_arvalid(S_AXI_HP0_0_arvalid),
        .S_AXI_HP0_0_awaddr(S_AXI_HP0_0_awaddr),
        .S_AXI_HP0_0_awburst(S_AXI_HP0_0_awburst),
        .S_AXI_HP0_0_awcache(S_AXI_HP0_0_awcache),
        .S_AXI_HP0_0_awid(S_AXI_HP0_0_awid),
        .S_AXI_HP0_0_awlen(S_AXI_HP0_0_awlen),
        .S_AXI_HP0_0_awlock(S_AXI_HP0_0_awlock),
        .S_AXI_HP0_0_awprot(S_AXI_HP0_0_awprot),
        .S_AXI_HP0_0_awqos(S_AXI_HP0_0_awqos),
        .S_AXI_HP0_0_awready(S_AXI_HP0_0_awready),
        .S_AXI_HP0_0_awsize(S_AXI_HP0_0_awsize),
        .S_AXI_HP0_0_awvalid(S_AXI_HP0_0_awvalid),
        .S_AXI_HP0_0_bid(S_AXI_HP0_0_bid),
        .S_AXI_HP0_0_bready(S_AXI_HP0_0_bready),
        .S_AXI_HP0_0_bresp(S_AXI_HP0_0_bresp),
        .S_AXI_HP0_0_bvalid(S_AXI_HP0_0_bvalid),
        .S_AXI_HP0_0_rdata(S_AXI_HP0_0_rdata),
        .S_AXI_HP0_0_rid(S_AXI_HP0_0_rid),
        .S_AXI_HP0_0_rlast(S_AXI_HP0_0_rlast),
        .S_AXI_HP0_0_rready(S_AXI_HP0_0_rready),
        .S_AXI_HP0_0_rresp(S_AXI_HP0_0_rresp),
        .S_AXI_HP0_0_rvalid(S_AXI_HP0_0_rvalid),
        .S_AXI_HP0_0_wdata(S_AXI_HP0_0_wdata),
        .S_AXI_HP0_0_wid(S_AXI_HP0_0_wid),
        .S_AXI_HP0_0_wlast(S_AXI_HP0_0_wlast),
        .S_AXI_HP0_0_wready(S_AXI_HP0_0_wready),
        .S_AXI_HP0_0_wstrb(S_AXI_HP0_0_wstrb),
        .S_AXI_HP0_0_wvalid(S_AXI_HP0_0_wvalid),
        .S_AXI_HP1_0_araddr(S_AXI_HP1_0_araddr),
        .S_AXI_HP1_0_arburst(S_AXI_HP1_0_arburst),
        .S_AXI_HP1_0_arcache(S_AXI_HP1_0_arcache),
        .S_AXI_HP1_0_arid(S_AXI_HP1_0_arid),
        .S_AXI_HP1_0_arlen(S_AXI_HP1_0_arlen),
        .S_AXI_HP1_0_arlock(S_AXI_HP1_0_arlock),
        .S_AXI_HP1_0_arprot(S_AXI_HP1_0_arprot),
        .S_AXI_HP1_0_arqos(S_AXI_HP1_0_arqos),
        .S_AXI_HP1_0_arready(S_AXI_HP1_0_arready),
        .S_AXI_HP1_0_arsize(S_AXI_HP1_0_arsize),
        .S_AXI_HP1_0_arvalid(S_AXI_HP1_0_arvalid),
        .S_AXI_HP1_0_awaddr(S_AXI_HP1_0_awaddr),
        .S_AXI_HP1_0_awburst(S_AXI_HP1_0_awburst),
        .S_AXI_HP1_0_awcache(S_AXI_HP1_0_awcache),
        .S_AXI_HP1_0_awid(S_AXI_HP1_0_awid),
        .S_AXI_HP1_0_awlen(S_AXI_HP1_0_awlen),
        .S_AXI_HP1_0_awlock(S_AXI_HP1_0_awlock),
        .S_AXI_HP1_0_awprot(S_AXI_HP1_0_awprot),
        .S_AXI_HP1_0_awqos(S_AXI_HP1_0_awqos),
        .S_AXI_HP1_0_awready(S_AXI_HP1_0_awready),
        .S_AXI_HP1_0_awsize(S_AXI_HP1_0_awsize),
        .S_AXI_HP1_0_awvalid(S_AXI_HP1_0_awvalid),
        .S_AXI_HP1_0_bid(S_AXI_HP1_0_bid),
        .S_AXI_HP1_0_bready(S_AXI_HP1_0_bready),
        .S_AXI_HP1_0_bresp(S_AXI_HP1_0_bresp),
        .S_AXI_HP1_0_bvalid(S_AXI_HP1_0_bvalid),
        .S_AXI_HP1_0_rdata(S_AXI_HP1_0_rdata),
        .S_AXI_HP1_0_rid(S_AXI_HP1_0_rid),
        .S_AXI_HP1_0_rlast(S_AXI_HP1_0_rlast),
        .S_AXI_HP1_0_rready(S_AXI_HP1_0_rready),
        .S_AXI_HP1_0_rresp(S_AXI_HP1_0_rresp),
        .S_AXI_HP1_0_rvalid(S_AXI_HP1_0_rvalid),
        .S_AXI_HP1_0_wdata(S_AXI_HP1_0_wdata),
        .S_AXI_HP1_0_wid(S_AXI_HP1_0_wid),
        .S_AXI_HP1_0_wlast(S_AXI_HP1_0_wlast),
        .S_AXI_HP1_0_wready(S_AXI_HP1_0_wready),
        .S_AXI_HP1_0_wstrb(S_AXI_HP1_0_wstrb),
        .S_AXI_HP1_0_wvalid(S_AXI_HP1_0_wvalid),
        .aux_reset_in_0(aux_reset_in_0),
        .dcm_locked_0(dcm_locked_0),
        .fifo_reset(fifo_reset),
        .fifo_reset_1(fifo_reset_1),
        .logic_clk(logic_clk),
        .logic_clk_pll_locked(logic_clk_pll_locked),
        .periph_reset(periph_reset),
        .pixel_clk(pixel_clk),
        .pixel_clk_pll_locked(pixel_clk_pll_locked),
        .pll_resets(pll_resets),
        .ref_clk(ref_clk),
        .ref_clk_pll_locked(ref_clk_pll_locked),
        .resetn(resetn),
        .valid_0(valid_0),
        .valid_1(valid_1),
        .wr_clk_0(wr_clk_0),
        .wr_clk_1(wr_clk_1));
endmodule
