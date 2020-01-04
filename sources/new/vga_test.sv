/*
Main Module for High Frame Rate Camera (HFRC) PYTHON 1300
By: Yamn Chalich

AXI-Interface code obtained from Alex Lao of McMaster University
https://github.com/AlexLao512
and modified for the purpose of this project
*/

`timescale 1ns / 1ps
//`ifdef DISABLE_DEFAULT_NET
//`else
//`default_nettype none
//`endif

//////////////////////////////////////////////////////////////////////////////////

module vga_test(
    input logic  [5:0]  PB          ,
    input logic  [3:0]  SWITCH      ,
    output logic [3:0]  LED         ,
    /*--------CAMERA--------*/
    //LVDS
    input logic LVDS_CLK_P,
    input logic LVDS_CLK_N,
    input logic LVDS_SYNC_P,
    input logic LVDS_SYNC_N,
    input logic LVDS_DIN3_P,
    input logic LVDS_DIN3_N,
    input logic LVDS_DIN2_P,
    input logic LVDS_DIN2_N,
    input logic LVDS_DIN1_P,
    input logic LVDS_DIN1_N,
    input logic LVDS_DIN0_P,
    input logic LVDS_DIN0_N,
    // SPI
    input  logic SPI_MISO,
    output logic SPI_MOSI,
    output logic SPI_CLK,
    output logic SPI_SS_N,
    //NOT USED
    input logic MONITOR_0, //USED
    input logic MONITOR_1,
    input logic TRIGGER_0,
    input logic TRIGGER_1,
    input logic TRIGGER_2,
    // POWER
    output logic VDD_18_EN,                //1.8V enable
    output logic VDD_33_EN_0,              //3.3V enable 1
    output logic VDD_33_EN_1,              //3.3V enable 2
    output logic CAM_RESET_N,              //Sensor Reset
    // OUTPUT CLK
    output logic CLK_PLL,                  //output clock to PLL of sensor, 72 MHz
    /*----------------------*/
    /////// VGA interface                     ////////////
    //output logic VGA_CLOCK_O,                 // VGA clock
    output logic VGA_HSYNC_O,                 // VGA H_SYNC
    output logic VGA_VSYNC_O,                 // VGA V_SYNC
    //output logic VGA_BLANK_O,                 // VGA BLANK
    //output logic VGA_SYNC_O,                  // VGA SYNC
    output logic[3:0] VGA_RED_O,              // VGA red
    output logic[3:0] VGA_GREEN_O,            // VGA green
    output logic[3:0] VGA_BLUE_O,             // VGA blue
    inout  [14:0] DDR_addr         ,
    inout  [ 2:0] DDR_ba           ,
    inout         DDR_cas_n        ,
    inout         DDR_ck_n         ,
    inout         DDR_ck_p         ,
    inout         DDR_cke          ,
    inout         DDR_cs_n         ,
    inout  [ 3:0] DDR_dm           ,
    inout  [31:0] DDR_dq           ,
    inout  [ 3:0] DDR_dqs_n        ,
    inout  [ 3:0] DDR_dqs_p        ,
    inout         DDR_odt          ,
    inout         DDR_ras_n        ,
    inout         DDR_reset_n      ,
    inout         DDR_we_n         ,
    inout         FIXED_IO_ddr_vrn ,
    inout         FIXED_IO_ddr_vrp ,
    inout  [53:0] FIXED_IO_mio     ,
    inout         FIXED_IO_ps_clk  ,
    inout         FIXED_IO_ps_porb ,
    inout         FIXED_IO_ps_srstb
    );
    
    `include "VGA_Param.h"
    
    logic zynq_resetn;
    logic reset;
    logic pixel_clk;
    logic logic_clk;
    logic spi_clock;
    logic refclkin;
    //logic ila_clk;
    //logic switch_display;
    logic logic_clk_pll_locked;
    logic pixel_clk_pll_locked;
    logic ref_clk_pll_locked;
    logic plls_locked;
    logic start_reset;
    
    logic [31:0] fps_stored_count;
    logic [31:0] continuous_store_start;
    
    wire [1:0] PS_TO_PL;
    wire [3:0] PL_TO_PS_0;
    wire [31:0] PL_TO_PS_1;
    wire [31:0] PL_TO_PS_2;
    
    wire PS_PIC_STORING, PS_VID_STORING;
    wire PL_RES_256, PL_RES_VGA;
    reg PL_PIC_STORE_START, PL_VID_STORE_START;
    
    assign PL_TO_PS_0 = {PL_RES_256, PL_RES_VGA, PL_VID_STORE_START, PL_PIC_STORE_START};
    assign PL_TO_PS_1 = fps_stored_count;
    assign PL_TO_PS_2 = continuous_store_start;
    assign PS_VID_STORING = PS_TO_PL[1];
    assign PS_PIC_STORING = PS_TO_PL[0];
       
    (* ASYNC_REG = "TRUE" *) logic [7:0] reset_sync;
    
    /* Reset Sync */
    always_ff @(posedge logic_clk or posedge start_reset) begin
        if(start_reset) begin
            reset_sync <= '0;
        end else begin
            if (!SWITCH[3]) reset_sync[7:0] <= {reset_sync[6:0],1'b1};
        end
    end
    
    assign plls_locked = logic_clk_pll_locked && pixel_clk_pll_locked && ref_clk_pll_locked;
        
    /*----------------------------------------------------------------------------------*/
    /*-------------------------------------CAMERA---------------------------------------*/
    /*----------------------------------------------------------------------------------*/    
    logic vdd_en_18, vdd_en_33_0, vdd_en_33_1, clk_pll_en, SPI_CLOCK_START, cam_pll_locked;
    logic power_up_down, SPI_start, SPI_upload_done, SPI_upload_done_buffer, enable_LVDS_receiver, lvds_reset;
    
    logic [15:0] SPI_read_data;
    logic [8:0] upload_state;
    logic [25:0] spi_upload_data;
    logic [8:0] spi_rom_addr;
    logic [31:0] spi_rom_data;
    logic [25:0] spi_exposure_data;
    
    assign lvds_reset = reset || ~enable_LVDS_receiver;

    //---------------------------------------//
    //------------------SPI------------------//
    //---------------------------------------//
    
    rom_spi ROM_SPI_UNIT (
        .clka(logic_clk),
        .addra(spi_rom_addr),
        .douta(spi_rom_data)
     );
    
    SPI_Controller SPI_UNIT (
        .reset(reset),
        .SPI_START(SPI_start),
        .SCK(spi_clock),
        .SS_N(SPI_SS_N),
        .MOSI(SPI_MOSI),
        .MISO(SPI_MISO),
        .SPI_upload_data(spi_upload_data),
        .SPI_read_data(SPI_read_data),
        .UPLOAD_DONE(SPI_upload_done)
    );
    
    //---------------------------------------//
    //------------------LVDS-----------------//
    //---------------------------------------//
    
    logic [4:0] DATA_IN_P, DATA_IN_N;
    logic LVDS_INTERFACE_CLK;
    logic CHANGE_BITSLIP;
    assign DATA_IN_P = {LVDS_SYNC_P, LVDS_DIN3_P, LVDS_DIN2_P, LVDS_DIN1_P, LVDS_DIN0_P};
    assign DATA_IN_N = {LVDS_SYNC_N, LVDS_DIN3_N, LVDS_DIN2_N, LVDS_DIN1_N, LVDS_DIN0_N};
    
    // Parameters
    parameter integer D = 5 ;            // Set the number of inputs to be 5
    //parameter integer S = 10 ;           // Set the serdes factor to be 10
    wire [49:0] rxd ;            
    wire refclkint ;         
    wire refclkintbufg ;         
    wire rx_locked ;        
    wire rx_system_clk ;                    
    wire delay_ready ;        
    reg [3:0] bcount ;
    
    logic sync_reset;
    assign sync_reset = !rx_locked || lvds_reset;
    
    // 200 or 300 Mhz Reference Clock Input, 300 MHz receomended for bit rates > 1 Gbps
    IBUF iob_200m_in (
        .I (refclkin),
        .O (refclkint)
    );
    
    BUFG bufg_200_ref (
        .I (refclkint), 
        .O (refclkintbufg)
    );
        
    IDELAYCTRL icontrol (            // Instantiate input delay control block
        .REFCLK (refclkintbufg),
        .RST (lvds_reset),
        .RDY (delay_ready)
    );
        
    logic [9:0] SYNC_DATA, D0_DATA, D1_DATA, D2_DATA, D3_DATA;
    
    // Input clock and data   
    serdes_1_to_10_idelay_ddr #(
        .HIGH_PERFORMANCE_MODE("TRUE"),
        .D (D),                             // Number of data lines
        .REF_FREQ (200.0),                  // Set idelay control reference frequency, refclkin freq
        .CLKIN_PERIOD (2.777),              // Set input clock period, 360 MHz shown
        .DATA_FORMAT ("PER_CHANL"))         // PER_CLOCK or PER_CHANL data formatting
    rx0 (                      
        .clkin_p (LVDS_CLK_P),
        .clkin_n (LVDS_CLK_N),
        .datain_p (DATA_IN_P),
        .datain_n (DATA_IN_N),
        .enable_phase_detector (1'b1),      // enable phase detector (active alignment) operation
        .enable_monitor (1'b0),             // enables data eye monitoring
        .dcd_correct (1'b0),                // enables clock duty cycle correction
        .rxclk (),
        .idelay_rdy (delay_ready),
        .system_clk (LVDS_INTERFACE_CLK),
        .reset (lvds_reset),
        .rx_lckd (rx_locked),
        .bitslip (CHANGE_BITSLIP),
        .rx_data (rxd),
        .bit_rate_value (16'h720),          // required bit rate value in BCD
        .bit_time_value (),                 // bit time value
        .eye_info (),                       // data eye monitor per line
        .m_delay_1hot (),                   // sample point monitor per line
        .debug ()                           // debug bus
    );                    
    
    always @(posedge LVDS_INTERFACE_CLK) begin
        if (sync_reset) begin
            SYNC_DATA <= 10'd0 ;
            D3_DATA <= 10'd0;
            D2_DATA <= 10'd0;
            D1_DATA <= 10'd0;
            D0_DATA <= 10'd0;
        end else begin
            SYNC_DATA <= rxd[49:40];
            D3_DATA <= rxd[39:30];
            D2_DATA <= rxd[29:20];
            D1_DATA <= rxd[19:10];
            D0_DATA <= rxd[9:0];
        end
    end
    
    logic RAM_DATA_RDY;
    logic [63:0] RAM_DATA;
    logic [9:0] SYNC, D0, D1, D2, D3;
    
    logic new_frame_rdy, write_to_lvds_fifo;
    logic frame_buffer_ready;
    
    logic data_is_aligned;
    logic [2:0] LVDS_state;
    logic [19:0] num_of_lines;
    logic [2:0] bitslip_state;
    
    logic wait_for_30_fps;
    logic fps_count;
    
    LVDS_Interface LVDS_INTERFACE_UNIT (
        .CLK(LVDS_INTERFACE_CLK),
        //.test_clk(logic_clk),
        .sync_reset(sync_reset),
        .monitor_0(MONITOR_0),
        .SYNC_DATA_IN(SYNC_DATA),
        .D3_DATA_IN(D3_DATA),
        .D2_DATA_IN(D2_DATA),
        .D1_DATA_IN(D1_DATA),
        .D0_DATA_IN(D0_DATA),
        .frame_buffer_rdy(frame_buffer_ready),
        
        .new_frame_rdy(new_frame_rdy),
        .write_to_lvds_fifo(write_to_lvds_fifo),
        .wait_30_fps(wait_for_30_fps),
        .RAM_DATA(RAM_DATA),
        .RAM_DATA_RDY(RAM_DATA_RDY),
        .bitslip(CHANGE_BITSLIP), // output bitslip
        .fps_count(fps_count),
        
        .data_aligned(data_is_aligned),
        .lvds_state_o(LVDS_state),
        .num_lines(num_of_lines),
        .bitslip_state_o(bitslip_state)
    );
    
    enum logic [3:0] {
        S_OFF,
        S_POWER_ON,
        S_LOW_POWER_STANDBY,
        S_LOW_POWER_STANDBY_WAIT,
        S_STANDBY_1,
        S_INTERMEDIATE_STANDBY,
        S_STANDBY_2,
        S_IDLE,
        S_CHANGE_RES,
        S_CHANGE_EXPOSURE,
        S_IDLE_EN_DISABLE,
        S_RUNNING
    } HFRC_state;
       
    assign VDD_18_EN = vdd_en_18;
    assign VDD_33_EN_0 = vdd_en_33_0;
    assign VDD_33_EN_1 = vdd_en_33_1;
    assign CLK_PLL = (clk_pll_en) ? logic_clk : 1'b0;
    
    //20us COUNTER--------------------------------------------------
    //--------------------------------------------------------------
    logic [9:0] clock_div_count;
    logic ten_micro_sec_clock, ten_micro_sec_clock_buf;
    logic [2:0] counter;
    
    // A counter for clock division for 50kHz counter for power sequence start-up
    // Datasheet suggests >10us; 20us is used as pre-caution
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            clock_div_count <= 10'd0;
        end else begin
            if (HFRC_state == S_POWER_ON) begin
                if (clock_div_count < 10'd719) begin
                    clock_div_count <= clock_div_count + 10'd1;
                end else 
                    clock_div_count <= 10'd0;
            end else
                clock_div_count <= 10'd0;
        end
    end
    
    // The value of ten_micro_sec_clock flip-flop is inverted every time the counter is reset to zero
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            ten_micro_sec_clock <= 1'b1;
        end else begin
            if (HFRC_state == S_POWER_ON) begin
                if (clock_div_count == 10'd0) ten_micro_sec_clock <= ~ten_micro_sec_clock;
            end else
                ten_micro_sec_clock <= 1'b1;
        end
    end
    
    // A buffer on ten_micro_sec_clock for edge detection
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            ten_micro_sec_clock_buf <= 1'b1;
            counter <= 3'd0;
        end else begin
            if (HFRC_state == S_POWER_ON) begin
                ten_micro_sec_clock_buf <= ten_micro_sec_clock;
                if (ten_micro_sec_clock_buf == 1'b0 && ten_micro_sec_clock == 1'b1) begin
                    //enable count
                    counter <= counter + 3'd1;
                end
            end else begin
                counter <= 3'd0;
                ten_micro_sec_clock_buf <= 1'b1;
            end
        end
    end
    
    //--------------------------------------------------------------
    //--------------------------------------------------------------
    
    //SPI_CLK-------------------------------------------------------
    //--------------------------------------------------------------
    //set to 9 MHz -> 72/8
    logic [1:0] clock_spi_div_count;
    assign SPI_CLK = spi_clock;
    
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            clock_spi_div_count <= 2'd0; //2 bit -> 4
        end else begin
            if (SPI_CLOCK_START) begin
                clock_spi_div_count <= clock_spi_div_count + 2'd1;
                /*
                every 4 cycles, spi_clock will toggle
                one full cycle for spi_clock will be 8 cycles of 72 MHz
                spi_clock = 72/8 = 9 MHz
                */
            end else
                clock_spi_div_count <= 2'd0;
        end
    end
    
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            spi_clock <= 1'b0;
        end else begin
        if (SPI_CLOCK_START) begin
            if (clock_spi_div_count == 2'd0) spi_clock <= ~spi_clock;
        end else spi_clock <= 1'b1;
        end
    end
    
    //--------------------------------------------------------------
    //--------------------------------------------------------------
    
    //REGISTER UPLOADS----------------------------------------------
    //--------------------------------------------------------------
    //NOW STORED IN BRAM, BUT KEPT HERE FOR ILLUSTRATION
    /*
    always_comb begin case (HFRC_state)
        S_LOW_POWER_STANDBY: begin
            if (power_up_down) begin
                //EN CLOCK MANAGEMENT I
                case (upload_state)
                7'd0 : spi_upload_data = {9'd2, 1'b1, 16'h0000};
                7'd1 : spi_upload_data = {9'd8, 1'b1, 16'h0000};
                7'd2 : spi_upload_data = {9'd16, 1'b1, 16'h0003};
                7'd3 : spi_upload_data = {9'd17, 1'b1, 16'h2113};
                7'd4 : spi_upload_data = {9'd20, 1'b1, 16'h0000};
                7'd5 : spi_upload_data = {9'd26, 1'b1, 16'h2280};
                7'd6 : spi_upload_data = {9'd27, 1'b1, 16'h3D2D};
                7'd7 : spi_upload_data = {9'd32, 1'b1, 16'h7004};
                endcase
            end else begin
                //DISABLE CLOCK MANAGEMENT I
                case (upload_state)
                7'd0 : spi_upload_data = {9'd8, 1'b1, 16'h0099};
                7'd1 : spi_upload_data = {9'd16, 1'b1, 16'h0000};
                endcase
            end
        end
        
        S_LOW_POWER_STANDBY_WAIT: begin
            //read PLL_lock flag 24[0], then continue
            spi_upload_data = {9'd24, 1'b0, 16'h0000};
        end
        
        S_STANDBY_1: begin
            if (power_up_down) begin
                case (upload_state)
                //EN CLOCK MANAGEMENT II
                7'd0 : spi_upload_data = {9'd9, 1'b1, 16'h0000};
                7'd1 : spi_upload_data = {9'd32, 1'b1, 16'h7006};
                7'd2 : spi_upload_data = {9'd34, 1'b1, 16'h0001};
                endcase
            end else begin
                //DISABLE CLOCK MANAGEMENT II
                case (upload_state)
                7'd0 : spi_upload_data = {9'd9, 1'b1, 16'h0000};
                7'd1 : spi_upload_data = {9'd32, 1'b1, 16'h7004};
                7'd2 : spi_upload_data = {9'd34, 1'b1, 16'h0000};
                endcase
            end
        end
        
        S_INTERMEDIATE_STANDBY: begin
            //REQUIRED REG UPLOAD
            case (upload_state)
            7'd0 : spi_upload_data = {9'd41, 1'b1, 16'h085F};
            7'd1 : spi_upload_data = {9'd42, 1'b1, 16'h4110};
            7'd2 : spi_upload_data = {9'd43, 1'b1, 16'h0008};
            7'd3 : spi_upload_data = {9'd65, 1'b1, 16'h382B};
            7'd4 : spi_upload_data = {9'd66, 1'b1, 16'h53C8};
            7'd5 : spi_upload_data = {9'd67, 1'b1, 16'h0665};
            7'd6 : spi_upload_data = {9'd68, 1'b1, 16'h0085};
            7'd7 : spi_upload_data = {9'd69, 1'b1, 16'h0088};
            7'd8 : spi_upload_data = {9'd70, 1'b1, 16'h1111};
            7'd9 : spi_upload_data = {9'd72, 1'b1, 16'h0010};
            7'd10 : spi_upload_data = {9'd128, 1'b1, 16'h4714};
            7'd11 : spi_upload_data = {9'd129, 1'b1, 16'h8001};
            7'd12 : spi_upload_data = {9'd171, 1'b1, 16'h1002};
            7'd13 : spi_upload_data = {9'd175, 1'b1, 16'h0080};
            7'd14 : spi_upload_data = {9'd176, 1'b1, 16'h00E6};
            7'd15 : spi_upload_data = {9'd177, 1'b1, 16'h0400};
            7'd16 : spi_upload_data = {9'd192, 1'b1, 16'h080C};
            7'd17 : spi_upload_data = {9'd194, 1'b1, 16'h0224};
            7'd18 : spi_upload_data = {9'd197, 1'b1, 16'h0306};
            7'd19 : spi_upload_data = {9'd204, 1'b1, 16'h01E1};
            7'd20 : spi_upload_data = {9'd207, 1'b1, 16'h0000};
            7'd21 : spi_upload_data = {9'd211, 1'b1, 16'h0E49};
            7'd22 : spi_upload_data = {9'd215, 1'b1, 16'h111F};
            7'd23 : spi_upload_data = {9'd216, 1'b1, 16'h7F00};
            7'd24 : spi_upload_data = {9'd219, 1'b1, 16'h0020};
            7'd25 : spi_upload_data = {9'd220, 1'b1, 16'h3A28};
            7'd26 : spi_upload_data = {9'd221, 1'b1, 16'h624D};
            7'd27 : spi_upload_data = {9'd222, 1'b1, 16'h624D};
            7'd28 : spi_upload_data = {9'd224, 1'b1, 16'h3E5E};
            7'd29 : spi_upload_data = {9'd227, 1'b1, 16'h0000};
            7'd30 : spi_upload_data = {9'd250, 1'b1, 16'h2081};
            7'd31 : spi_upload_data = {9'd384, 1'b1, 16'hC800};
            7'd32 : spi_upload_data = {9'd385, 1'b1, 16'hFB1F};
            7'd33 : spi_upload_data = {9'd386, 1'b1, 16'hFB1F};
            7'd34 : spi_upload_data = {9'd387, 1'b1, 16'hFB12};
            7'd35 : spi_upload_data = {9'd388, 1'b1, 16'hF903};
            7'd36 : spi_upload_data = {9'd389, 1'b1, 16'hF802};
            7'd37 : spi_upload_data = {9'd390, 1'b1, 16'hF30F};
            7'd38 : spi_upload_data = {9'd391, 1'b1, 16'hF30F};
            7'd39 : spi_upload_data = {9'd392, 1'b1, 16'hF30F};
            7'd40 : spi_upload_data = {9'd393, 1'b1, 16'hF30A};
            7'd41 : spi_upload_data = {9'd394, 1'b1, 16'hF101};
            7'd42 : spi_upload_data = {9'd395, 1'b1, 16'hF00A};
            7'd43 : spi_upload_data = {9'd396, 1'b1, 16'hF24B};
            7'd44 : spi_upload_data = {9'd397, 1'b1, 16'hF226};
            7'd45 : spi_upload_data = {9'd398, 1'b1, 16'hF001};
            7'd46 : spi_upload_data = {9'd399, 1'b1, 16'hF402};
            7'd47 : spi_upload_data = {9'd400, 1'b1, 16'hF001};
            7'd48 : spi_upload_data = {9'd401, 1'b1, 16'hF402};
            7'd49 : spi_upload_data = {9'd402, 1'b1, 16'hF001};
            7'd50 : spi_upload_data = {9'd403, 1'b1, 16'hF401};
            7'd51 : spi_upload_data = {9'd404, 1'b1, 16'hF007};
            7'd52 : spi_upload_data = {9'd405, 1'b1, 16'hF20F};
            7'd53 : spi_upload_data = {9'd406, 1'b1, 16'hF20F};
            7'd54 : spi_upload_data = {9'd407, 1'b1, 16'hF202};
            7'd55 : spi_upload_data = {9'd408, 1'b1, 16'hF006};
            7'd56 : spi_upload_data = {9'd409, 1'b1, 16'hEC02};
            7'd57 : spi_upload_data = {9'd410, 1'b1, 16'hE801};
            7'd58 : spi_upload_data = {9'd411, 1'b1, 16'hEC02};
            7'd59 : spi_upload_data = {9'd412, 1'b1, 16'hE801};
            7'd60 : spi_upload_data = {9'd413, 1'b1, 16'hEC02};
            7'd61 : spi_upload_data = {9'd414, 1'b1, 16'hC801};
            7'd62 : spi_upload_data = {9'd415, 1'b1, 16'hC800};
            7'd63 : spi_upload_data = {9'd416, 1'b1, 16'hC800};
            7'd64 : spi_upload_data = {9'd417, 1'b1, 16'hCC02};
            7'd65 : spi_upload_data = {9'd418, 1'b1, 16'hC801};
            7'd66 : spi_upload_data = {9'd419, 1'b1, 16'hCC02};
            7'd67 : spi_upload_data = {9'd420, 1'b1, 16'hC801};
            7'd68 : spi_upload_data = {9'd421, 1'b1, 16'hCC02};
            7'd69 : spi_upload_data = {9'd422, 1'b1, 16'hC805};
            7'd70 : spi_upload_data = {9'd423, 1'b1, 16'hC800};
            7'd71 : spi_upload_data = {9'd424, 1'b1, 16'h0030};
            7'd72 : spi_upload_data = {9'd425, 1'b1, 16'h207C};
            7'd73 : spi_upload_data = {9'd426, 1'b1, 16'h2071};
            7'd74 : spi_upload_data = {9'd427, 1'b1, 16'h0074};
            7'd75 : spi_upload_data = {9'd428, 1'b1, 16'h107F};
            7'd76 : spi_upload_data = {9'd429, 1'b1, 16'h1072};
            7'd77 : spi_upload_data = {9'd430, 1'b1, 16'h1074};
            7'd78 : spi_upload_data = {9'd431, 1'b1, 16'h0076};
            7'd79 : spi_upload_data = {9'd432, 1'b1, 16'h0031};
            7'd80 : spi_upload_data = {9'd433, 1'b1, 16'h21BB};
            7'd81 : spi_upload_data = {9'd434, 1'b1, 16'h20B1};
            7'd82 : spi_upload_data = {9'd435, 1'b1, 16'h20B1};
            7'd83 : spi_upload_data = {9'd436, 1'b1, 16'h00B1};
            7'd84 : spi_upload_data = {9'd437, 1'b1, 16'h10BF};
            7'd85 : spi_upload_data = {9'd438, 1'b1, 16'h10B2};
            7'd86 : spi_upload_data = {9'd439, 1'b1, 16'h10B4};
            7'd87 : spi_upload_data = {9'd440, 1'b1, 16'h00B1};
            7'd88 : spi_upload_data = {9'd441, 1'b1, 16'h0030};
            7'd89 : spi_upload_data = {9'd442, 1'b1, 16'h0030};
            7'd90 : spi_upload_data = {9'd443, 1'b1, 16'h217B};
            7'd91 : spi_upload_data = {9'd444, 1'b1, 16'h2071};
            7'd92 : spi_upload_data = {9'd445, 1'b1, 16'h2071};
            7'd93 : spi_upload_data = {9'd446, 1'b1, 16'h0074};
            7'd94 : spi_upload_data = {9'd447, 1'b1, 16'h107F};
            7'd95 : spi_upload_data = {9'd448, 1'b1, 16'h1072};
            7'd96 : spi_upload_data = {9'd449, 1'b1, 16'h1074};
            7'd97 : spi_upload_data = {9'd450, 1'b1, 16'h0076};
            7'd98 : spi_upload_data = {9'd451, 1'b1, 16'h0031};
            7'd99 : spi_upload_data = {9'd452, 1'b1, 16'h20BB};
            7'd100 : spi_upload_data = {9'd453, 1'b1, 16'h20B1};
            7'd101 : spi_upload_data = {9'd454, 1'b1, 16'h20B1};
            7'd102 : spi_upload_data = {9'd455, 1'b1, 16'h00B1};
            7'd103 : spi_upload_data = {9'd456, 1'b1, 16'h10BF};
            7'd104 : spi_upload_data = {9'd457, 1'b1, 16'h10B2};
            7'd105 : spi_upload_data = {9'd458, 1'b1, 16'h10B4};
            7'd106 : spi_upload_data = {9'd459, 1'b1, 16'h00B1};
            7'd107 : spi_upload_data = {9'd460, 1'b1, 16'h0030};
            endcase
        end
        
        S_STANDBY_2: begin
            if (power_up_down) begin
                //SOFT POWER UP REG UPLOAD
                case (upload_state)
                7'd0 : spi_upload_data = {9'd10, 1'b1, 16'h0000};
                7'd1 : spi_upload_data = {9'd32, 1'b1, 16'h7007};
                7'd2 : spi_upload_data = {9'd40, 1'b1, 16'h0003};
                7'd3 : spi_upload_data = {9'd42, 1'b1, 16'h4113};
                7'd4 : spi_upload_data = {9'd48, 1'b1, 16'h0001};
                7'd5 : spi_upload_data = {9'd64, 1'b1, 16'h0001};
                7'd6 : spi_upload_data = {9'd72, 1'b1, 16'h0017};
                7'd7 : spi_upload_data = {9'd112, 1'b1, 16'h0007};
                endcase
            end else begin
                //SOFT POWER DOWN REG UPLOAD
                case (upload_state)
                7'd0 : spi_upload_data = {9'd10, 1'b1, 16'h0999};
                7'd1 : spi_upload_data = {9'd32, 1'b1, 16'h7006};
                7'd2 : spi_upload_data = {9'd40, 1'b1, 16'h0000};
                7'd3 : spi_upload_data = {9'd42, 1'b1, 16'h4110};
                7'd4 : spi_upload_data = {9'd48, 1'b1, 16'h0000};
                7'd5 : spi_upload_data = {9'd64, 1'b1, 16'h0000};
                7'd6 : spi_upload_data = {9'd72, 1'b1, 16'h0010};
                7'd7 : spi_upload_data = {9'd112, 1'b1, 16'h0000};
                endcase
            end
        end
        
        S_IDLE_EN_DISABLE: begin
            if (power_up_down)
                //EN SEQUENCER
                spi_upload_data = {9'd192, 1'b1, 16'h080D};
            else
                //DISABLE SEQUENCER
                spi_upload_data = {9'd192, 1'b1, 16'h080C};
        end
        
        default : spi_upload_data = 26'h0000;
    endcase end
    
    logic [1:0] expo_count;
    logic spi_upload_switch;
    
    always_comb begin
        if (expo_count == 2'd0) spi_exposure_data = 26'b01100001010000001000110100; //194, exposure > readout
        if (expo_count == 2'd1) spi_exposure_data = 26'b01100100011001001001111100; //200 time for frame = 3.5 frames 37500
        //if (expo_count == 2'd2) spi_exposure_data = 26'b01100100110111110110001111; //201 time for exposure = 3 frames 32143
        else spi_exposure_data = 26'b01100011110000000000100000; //199 granularity 32x
    
    end
    */
    //--------------------------------------------------------------
    //--------------------------------------------------------------
        
    always_ff @(posedge logic_clk) begin
        if (reset) begin
            spi_upload_data <= 26'd0;
            SPI_upload_done_buffer <= 1'b0;
        end else begin
            spi_upload_data <= spi_rom_data[25:0];
            SPI_upload_done_buffer <= SPI_upload_done;
        end
    end
    
    logic error_with_spi_upload, res_256, res_vga;
    logic expo_30, expo_60, expo_switch;
    logic [8:0] expo_base_rom_address;
    assign expo_base_rom_address = 9'd278;
    
    always_ff @(posedge pixel_clk) begin
        if (reset) begin
            res_256 <= 1'b0;
            res_vga <= 1'b0;
            expo_switch <= 1'b0;
            expo_30 <= 1'b0;
            expo_60 <= 1'b0;
            if (!SWITCH[0] && SWITCH[1]) begin
                expo_switch <= 1'b1;
                if (!SWITCH[2]) begin
                    //MAX RES, 30 FPS HIGHEST EXPOSURE
                    expo_30 <= 1'b1;
                end else
                    //MAX RES, 60 FPS HIGHEST EXPOSURE
                    expo_60 <= 1'b1;
            end else begin
                if (SWITCH[2])
                    //ANY RES, (100, 400, 1000 FPS) (>2x EXPOSURE)
                    expo_switch <= 1'b1;
                if (SWITCH[0]) begin
                    if (SWITCH[1])
                        res_256 <= 1'b1;
                    else 
                        res_vga <= 1'b1;
                end
            end     
        end
    end
    
    assign PL_RES_256 = res_256; 
    assign PL_RES_VGA = res_vga;
    
    always_ff @(posedge logic_clk) begin
        if (reset) begin
            HFRC_state <= S_OFF;
            CAM_RESET_N <= 1'b0;
            upload_state <= 9'd0;
            vdd_en_18 <= 1'b0;
            vdd_en_33_0 <= 1'b0;
            vdd_en_33_1 <= 1'b0;
            clk_pll_en <= 1'b0;
            SPI_start <= 1'b0;
            enable_LVDS_receiver <= 1'b0;
            power_up_down <= 1'b0;
            cam_pll_locked <= 1'b0;
            SPI_CLOCK_START <= 1'b0;
            spi_rom_addr <= 9'd0;
            error_with_spi_upload <= 1'b0;
            start_reset <= 1'b0;
        end else begin
            case (HFRC_state)
            S_OFF: begin
                if (!start_reset) begin
                    HFRC_state <= S_POWER_ON;
                    power_up_down <= 1'b1;
                end
            end
            S_POWER_ON: begin
                if (power_up_down) begin
                    if (counter == 3'd1)
                        vdd_en_18 <= 1'b1;
                    else if (counter == 3'd2)
                        vdd_en_33_0 <= 1'b1;
                    else if (counter == 3'd3)
                        vdd_en_33_1 <= 1'b1;
                    else if (counter == 3'd4)
                        clk_pll_en <= 1'b1;
                    else if (counter == 3'd5)
                        CAM_RESET_N <= 1'b1;
                    else if (counter == 3'd6) begin
                        HFRC_state <= S_LOW_POWER_STANDBY;
                        SPI_CLOCK_START <= 1'b1;
                        SPI_start <= 1'b1;
                    end
                end else begin
                    if (counter == 3'd1) begin
                        CAM_RESET_N <= 1'b0;
                    end else if (counter == 3'd2) begin
                        clk_pll_en <= 1'b0;
                        SPI_CLOCK_START <= 1'b0;
                    end else if (counter == 3'd3)
                        vdd_en_33_1 <= 1'b0;
                    else if (counter == 3'd4)
                        vdd_en_33_0 <= 1'b0;
                    else if (counter == 3'd5) begin
                        vdd_en_18 <= 1'b0;
                        start_reset <= 1'b1;
                        HFRC_state <= S_OFF;
                    end
                end
            end
            S_LOW_POWER_STANDBY: begin
                if (power_up_down) begin
                    if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                        upload_state <= upload_state + 9'd1;
                        spi_rom_addr <= spi_rom_addr + 9'd1;
                        if (upload_state == 9'd15) begin
                            HFRC_state <= S_LOW_POWER_STANDBY_WAIT;
                            upload_state <= 9'd0;
                        end
                    end
                end else begin
                    if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                        upload_state <= upload_state + 9'd1;
                        spi_rom_addr <= spi_rom_addr + 9'd1;
                        if (upload_state == 9'd1) begin
                            HFRC_state <= S_POWER_ON;
                            upload_state <= 9'd0;
                        end
                    end
                end
            end
            S_LOW_POWER_STANDBY_WAIT: begin
                if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                    if (SPI_read_data[0]) begin
                        //pll is locked
                        cam_pll_locked <= 1'b1;
                        spi_rom_addr <= spi_rom_addr + 9'd1;
                        HFRC_state <= S_STANDBY_1;
                    end
                end
            end
            S_STANDBY_1: begin
                if (power_up_down) begin
                    if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                        upload_state <= upload_state + 9'd1;
                        spi_rom_addr <= spi_rom_addr + 9'd1;
                        if (upload_state == 9'd5) begin
                            HFRC_state <= S_INTERMEDIATE_STANDBY;
                            upload_state <= 9'd0;
                        end
                    end
                end else begin
                    if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                        upload_state <= upload_state + 9'd1;
                        spi_rom_addr <= spi_rom_addr + 9'd1;
                        if (upload_state == 9'd2) begin
                            HFRC_state <= S_LOW_POWER_STANDBY;
                            upload_state <= 9'd0;
                        end
                    end
                end
            end
            S_INTERMEDIATE_STANDBY: begin
                if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                    upload_state <= upload_state + 9'd1;
                    spi_rom_addr <= spi_rom_addr + 9'd1;
                    if (upload_state == 9'd215) begin
                        HFRC_state <= S_STANDBY_2;
                        upload_state <= 9'd0;
                    end
                end
            end
            S_STANDBY_2: begin
                if (power_up_down) begin
                    if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                        upload_state <= upload_state + 9'd1;
                        spi_rom_addr <= spi_rom_addr + 9'd1;
                        if (upload_state == 9'd17) begin
                            if (expo_switch) begin
                                HFRC_state <= S_CHANGE_EXPOSURE;
                                SPI_start <= 1'b1;
                                upload_state <= 9'd0;
                                if (expo_30) spi_rom_addr <= expo_base_rom_address;
                                else if (expo_60) spi_rom_addr <= expo_base_rom_address + 9'd4;
                                else if (res_256) spi_rom_addr <= expo_base_rom_address + 9'd8;
                                else if (res_vga) spi_rom_addr <= expo_base_rom_address + 9'd12;
                                else spi_rom_addr <= expo_base_rom_address + 9'd16;
                            end else begin
                                HFRC_state <= S_IDLE;
                                upload_state <= 9'd0;
                                SPI_start <= 1'b0;
                            end
                        end
                    end
                end else begin
                    if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                        upload_state <= upload_state + 9'd1;
                        spi_rom_addr <= spi_rom_addr + 9'd1;
                        if (upload_state == 9'd7) begin
                            HFRC_state <= S_STANDBY_1;
                            upload_state <= 9'd0;
                        end
                    end
                end
            end
            S_IDLE: begin
                if (power_up_down) begin
                    if (res_256) begin
                        //256x256 resolution
                        spi_rom_addr <= 9'd275;
                        HFRC_state <= S_CHANGE_RES;
                    end else if (res_vga) begin
                        //VGA resolution
                        spi_rom_addr <= 9'd272;
                        HFRC_state <= S_CHANGE_RES;
                    end else begin
                        //ENABLE SEQUENCER
                        HFRC_state <= S_IDLE_EN_DISABLE;
                        spi_rom_addr <= 9'd257;
                    end
                    SPI_start <= 1'b1;
                end else begin
                    //SOFT POWER DOWN
                    HFRC_state <= S_STANDBY_2;
                    SPI_start <= 1'b1;
                    spi_rom_addr <= 9'd259;
                    upload_state <= 9'd0;
                end
            end
            S_CHANGE_RES: begin
                if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                    upload_state <= upload_state + 9'd1;
                    spi_rom_addr <= spi_rom_addr + 9'd1;
                    if (upload_state == 9'd2) begin
                        //ENABLE SEQUENCER
                        HFRC_state <= S_IDLE_EN_DISABLE;
                        SPI_start <= 1'b1;
                        spi_rom_addr <= 9'd257;
                    end
                end
            end
            S_CHANGE_EXPOSURE: begin
                if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                    upload_state <= upload_state + 9'd1;
                    spi_rom_addr <= spi_rom_addr + 9'd1;
                    if (upload_state == 9'd3) begin
                        //GO TO IDLE
                        HFRC_state <= S_IDLE;
                        upload_state <= 9'd0;
                        SPI_start <= 1'b0;
                    end
                end
            end
            S_IDLE_EN_DISABLE: begin    
                if (power_up_down) begin
                    if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                        HFRC_state <= S_RUNNING;
                        enable_LVDS_receiver <= 1'b1;
                        SPI_start <= 1'b0;
                    end
                end else begin
                    if (SPI_upload_done && ~SPI_upload_done_buffer) begin
                        HFRC_state <= S_IDLE;
                        SPI_start <= 1'b0;
                    end
                end
            end
            S_RUNNING: begin
                if (SWITCH[3]) begin
                    //DISABLE SEQUENCER
                    HFRC_state <= S_IDLE_EN_DISABLE;
                    power_up_down <= 1'b0;
                    enable_LVDS_receiver <= 1'b0;
                    SPI_start <= 1'b1;
                    spi_rom_addr <= 9'd258;
                end
            end
            default: HFRC_state <= S_OFF;
            endcase
        end
    end
    /*----------------------------------------------------------------------------------*/
    
    //STORAGE MODE CHECK FOR PUSHBUTTON
    logic storing, en_store_write;
    //logic [9:0] debounce_shift_reg;
    logic push_button_status, push_button_status_buf;
    assign push_button_status = PB[0];
    
    // Push button status is checked here
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            storing <= 1'b0;
            push_button_status_buf <= 1'b0;
        end else begin
            storing <= storing;
            push_button_status_buf <= push_button_status;
            if (push_button_status_buf == 1'b0 && push_button_status == 1'b1 && en_store_write == 1'b0) begin
                if (!(PL_VID_STORE_START || PL_PIC_STORE_START))
                    //if storage taking place (LED blinking), don't turn off storing mode
                    storing <= ~storing;
            end  
        end
    end
    
    //this is a fake 30/60 fps mode, just cutting out frames from the 210 fps mode
    //logic fps_60, fps_30, fps_60_button, fps_60_button_buf;
    //assign fps_60_button = PB[2];
    
    logic continuous_rec, cont_rec_button, cont_rec_button_buf;
    assign cont_rec_button = PB[4];
        
    // FPS push button status is checked here
    always_ff @ (posedge pixel_clk) begin
        if (reset) begin
            //fps_30 <= 1'b0;
            //fps_60 <= 1'b0;
            //fps_60_button_buf <= 1'b0;
            cont_rec_button_buf <= 1'b0;
            continuous_rec <= 1'b0;
        end else begin
            cont_rec_button_buf <= cont_rec_button;
            /*                   
            fps_60_button_buf <= fps_60_button;
            if (fps_60_button && !fps_60_button_buf) begin 
                fps_60 <= 1'b1;
                fps_30 <= 1'b0;
                if (fps_60) begin 
                    fps_60 <= 1'b0;
                    fps_30 <= 1'b1;
                end else if (fps_30) begin
                    fps_60 <= 1'b0;
                    fps_30 <= 1'b0;
                end
            end
            */
            if (cont_rec_button && !cont_rec_button_buf) continuous_rec <= ~continuous_rec;
        end
    end
    
    logic colour_mode_button, colour_mode, colour_mode_button_buf;
    assign colour_mode_button = PB[1];
    //
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            colour_mode <= 1'b0;
            colour_mode_button_buf <= 1'b0;
        end else begin
            colour_mode_button_buf <= colour_mode_button;
            if (colour_mode_button && !colour_mode_button_buf) colour_mode <= ~colour_mode;
        end
    end
    
    // For VGA
    logic [9:0] VGA_red, VGA_green, VGA_blue;
    logic [9:0] VGA_RED_O_long, VGA_GREEN_O_long, VGA_BLUE_O_long;
    
    //offset of 32'h0014_0000 accounts for C application code; estimated to 1 frame
    localparam bit [31:0] FB1_OFFSET = 32'h0010_0000 + 32'h0014_0000;
    localparam bit [31:0] FB2_OFFSET = 32'h0024_0000 + 32'h0014_0000;
    
    logic [31:0] FB1_RES_OFFSET;
    assign FB1_RES_OFFSET = (res_vga) ? (32'h0015_5140 + 32'h0014_0000) : (res_256) ? (32'h0017_8200 + 32'h0014_0000) : (32'h0010_0000 + 32'h0014_0000);
    
    logic [31:0] FB2_RES_OFFSET;
    assign FB2_RES_OFFSET = (res_vga) ? (32'h0029_5140 + 32'h0014_0000) : (res_256) ? (32'h002B_8200 + 32'h0014_0000) : (32'h0024_0000 + 32'h0014_0000);

    logic [6:0] res_count_max;
    assign res_count_max = (res_vga) ? 7'd79 : (res_256) ? 7'd31 : 7'd0;
    
    localparam bit [31:0] STORAGE_PIC_OFFSET = 32'h0038_0000 + 32'h0014_0000;
    localparam bit [31:0] STORAGE_FULL_OFFSET = 32'h004C_0000 + 32'h0014_0000;
    
    logic start_recording, start_taking_pic, recording;
    logic blanking;
    assign start_recording = PB[5];
    assign start_taking_pic = PB[3];
    
    logic [31:0] STORAGE_OFFSET;
    assign STORAGE_OFFSET = (recording) ? STORAGE_FULL_OFFSET : STORAGE_PIC_OFFSET;
        
    logic [31:0] read_count_reset, write_count_reset, write_count_storage_reset;
    assign read_count_reset = 32'd163839;
    assign write_count_reset = (blanking) ? 32'd163839 : (res_vga) ? 32'd76719 : (res_256) ? 32'd40831 : 32'd163839;
    
    always_comb begin
        if (recording) begin
            //3FFF_FFFF - 0010_0000 (offset) - 3 max frames (framebuffers + pic) - application space (0014_0000, same as 1 frame) = 0x3FA0_0000 space remaining; divide by frame size gives # of frames
            //# of frames * frame_size / 8 = reset_count:
            //eg. 814 * 1280 * 1024 / 8 = 133365760;
            if (res_vga) write_count_storage_reset = 32'd133401599; //vga - 3474 frames
            else if (res_256) write_count_storage_reset = 32'd133431295; //256 - 16288 frames 
            else write_count_storage_reset = 32'd133365759; //max - 814 frames
        end else begin
            if (res_vga) write_count_storage_reset = 32'd38399;
            else if (res_256) write_count_storage_reset = 32'd8191;
            else write_count_storage_reset = 32'd163839;
       end
    end
    
    logic [17:0] frame_count_max;
    
    always_comb begin
        if (res_vga) frame_count_max = 18'd38399;
        else if (res_256) frame_count_max = 18'd8191;
        else frame_count_max = 18'd163839; //1280 x 1024 / 8
    end
    
    //STORING OR RECORDING LED CONTROL
    logic blink_LED;
    logic [23:0] LED_counter;

    // A counter for 1/3 sec clock division
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            LED_counter <= 24'h0000000;
        end else begin
            if (recording || PS_VID_STORING || PS_PIC_STORING) begin
                if (LED_counter < 'd11999999)
                    LED_counter <= LED_counter + 25'd1;
                else 
                    LED_counter <= 24'h0000000; 
            end else
                LED_counter <= 24'h0000000;
        end
    end
    
    // The value of LED flip-flop is inverted every time the counter is reset to zero
    always_ff @ (posedge logic_clk) begin
        if (reset) begin
            blink_LED  <= 1'b0;
        end else begin
            blink_LED  <= blink_LED;
            if (LED_counter == 'd0) begin
                blink_LED <= ~blink_LED;
            end
            if (!(recording || PS_VID_STORING || PS_PIC_STORING)) blink_LED  <= 1'b0;
        end
    end
    
    logic bram_works;
    assign bram_works = 1'b0;
    //LED light assignment on FMC carrier; //expo_switch
    assign LED = {continuous_rec, bram_works, blink_LED, storing};
    
    /* m_axi_hp0 -> S_AXI_HP0_0 Interface */
    logic [31:0] m_axi_hp0_araddr ;
    logic        m_axi_hp0_arready;
    logic        m_axi_hp0_arvalid;

    logic [31:0] m_axi_hp0_awaddr ;
    logic        m_axi_hp0_awready;
    logic        m_axi_hp0_awvalid;

    logic [ 1:0] m_axi_hp0_bresp ;
    logic        m_axi_hp0_bready;
    logic        m_axi_hp0_bvalid;

    logic [63:0] m_axi_hp0_rdata ;
    logic        m_axi_hp0_rready;
    logic        m_axi_hp0_rvalid;

    logic [63:0] m_axi_hp0_wdata ;
    logic        m_axi_hp0_wready;
    logic        m_axi_hp0_wvalid;
    
    /* m_axi_hp1 -> s_axi_hp1 Interface */
    logic [31:0] m_axi_hp1_araddr ;
    logic        m_axi_hp1_arready;
    logic        m_axi_hp1_arvalid;

    logic [31:0] m_axi_hp1_awaddr ;
    logic        m_axi_hp1_awready;
    logic        m_axi_hp1_awvalid;

    logic [ 1:0] m_axi_hp1_bresp ;
    logic        m_axi_hp1_bready;
    logic        m_axi_hp1_bvalid;

    logic [63:0] m_axi_hp1_rdata ;
    logic        m_axi_hp1_rready;
    logic        m_axi_hp1_rvalid;

    logic [63:0] m_axi_hp1_wdata ;
    logic        m_axi_hp1_wready;
    logic        m_axi_hp1_wvalid;
    
    //**********************************
    
    logic [63:0] temp_data          ;
    logic [31:0] write_counter      ;
    logic [31:0] write_storage_counter;
    
    /*LVDS FIFO Interface   */
    logic        lvds_fifo_empty;
    logic [63:0] lvds_fifo_rd_data;
    logic        lvds_fifo_rd_en;
    logic        lvds_fifo_rd_valid;
    
    logic        lvds_fifo_full;    
    logic [63:0] lvds_fifo_wr_data;
    logic        lvds_fifo_wr_en;
    
    logic        lvds_fifo_empty_1;
    logic [63:0] lvds_fifo_rd_data_1;
    logic        lvds_fifo_rd_en_1;
    logic        lvds_fifo_rd_valid_1;
    
    logic        lvds_fifo_full_1;    
    logic [63:0] lvds_fifo_wr_data_1;
    logic        lvds_fifo_wr_en_1;
          
    /* Pixel FIFO Interface */
    logic        pixel_fifo_write_en;
    logic        pixel_fifo_read_en ;
    logic [63:0] pixel_fifo_din     ;
    logic        pixel_fifo_empty   ;
    logic        pixel_fifo_full    ;
    logic [63:0] pixel_fifo_dout    ;
    logic [ 4:0] pixel_fifo_level   ; 
    
    logic [31:0] read_counter           ;
    logic output_buffer_switch          ;
    logic output_buffer_switch_last     ;
    logic output_buffer_id              ;
    logic output_buffer_id_last         ;
    logic output_buffer_switch_triggered;
    
    //////////////////////////////////////////////////////////////////////////
    // DDR3 Framebuffer -> VGA/HDMI
    //////////////////////////////////////////////////////////////////////////
    
    // Uses m_axi_hp0 AR and R channels (R channel controlled by FIFO and VGA Driver)
    always_ff @ (posedge pixel_clk) begin
        if (reset) begin
            m_axi_hp0_araddr  <= 32'h0000_0000;
            m_axi_hp0_arvalid <= 1'b0;

            read_counter <= '0;
        end else begin
            m_axi_hp0_araddr  <= (output_buffer_id ? FB1_OFFSET : FB2_OFFSET) + ((read_counter<<3));
            if (pixel_fifo_full) 
                m_axi_hp0_arvalid <= 1'b0;
            else m_axi_hp0_arvalid <= 1'b1;
            if(m_axi_hp0_arready && m_axi_hp0_arvalid) begin
                if (read_counter < read_count_reset) begin
                    read_counter     <= read_counter + 1;
                    m_axi_hp0_araddr <= (output_buffer_id ? FB1_OFFSET : FB2_OFFSET) + (((read_counter+1)<<3));
                end else begin
                    read_counter     <= '0;
                    m_axi_hp0_araddr <= (output_buffer_id ? FB1_OFFSET : FB2_OFFSET);
                end
            end
        end
    end

    // Framebuffer Swap
    // Waits for output_buffer_switch rising edge
    // Switches frame buffers when DDR3 Framebuffer -> VGA/HDMI is done reading from its current buffer
    always_ff @(posedge pixel_clk) begin
        if(reset) begin
            output_buffer_id               <= '0;
            output_buffer_switch_last      <= '0;
            output_buffer_switch_triggered <= 1'b0;
        end else begin
            output_buffer_switch_last <= output_buffer_switch;
            output_buffer_id_last     <= output_buffer_id;
            if (output_buffer_switch  && !output_buffer_switch_last) begin
                output_buffer_switch_triggered <= 1'b1;
            end
            if (read_counter == read_count_reset && output_buffer_switch_triggered) begin
                output_buffer_switch_triggered <= 1'b0;
                output_buffer_id               <= output_buffer_id + 1;
            end

        end
    end
    
    //////////////////////////////////////////////////////////////////////////
    
    //lvds data fifo write side
    assign lvds_fifo_wr_en    = !lvds_fifo_full && RAM_DATA_RDY && write_to_lvds_fifo && !blanking;
    assign lvds_fifo_wr_data  = RAM_DATA;
    
    //lvds data fifo write side
    /*
    assign lvds_fifo_wr_en_1    = (fps_60) ? (!lvds_fifo_full && RAM_DATA_RDY && en_store_write && write_to_lvds_fifo) : 
                                  (fps_30) ? (!lvds_fifo_full && RAM_DATA_RDY && en_store_write && write_to_lvds_fifo && wait_for_30_fps) : 
                                  (!lvds_fifo_full_1 && RAM_DATA_RDY && en_store_write);
    */
    assign lvds_fifo_wr_en_1    = (!lvds_fifo_full_1 && RAM_DATA_RDY && en_store_write);
    assign lvds_fifo_wr_data_1  = RAM_DATA;
    
    // Main State Machine
    typedef enum logic {
        DDR3_W_IDLE,
        DDR3_W_ADDR_WRITE
    } ddr3_w_state_t;

    ddr3_w_state_t ddr3_w_state;
    
    logic ram_ready, image_ready, wdone, awdone, frame_done;
    logic [31:0] write_offset;
    logic [6:0] write_offset_counter;
    logic first_blank;
    
    assign frame_buffer_ready = ram_ready;
    
    logic rst_block;
    always_ff @(posedge logic_clk or posedge reset)
    begin
      if (reset) rst_block <= 1'b1;
      else rst_block <= reset;
    end
    
    always_ff @ (posedge pixel_clk) begin
        if (rst_block) begin
            ddr3_w_state <= DDR3_W_IDLE;

            m_axi_hp0_awaddr  <= 32'h0000_0000;
            m_axi_hp0_awvalid <= 1'b0;

            m_axi_hp0_wdata  <= '0;
            m_axi_hp0_wvalid <= 1'b0;
            
            //////////////////////////////////////////

            write_counter    <= '0;
            wdone <= 1'b0;
            awdone <= 1'b0;
            output_buffer_switch <= 1'b1;
            ram_ready <= 1'b0;
            image_ready <= 1'b0;
            
            write_offset <= 32'd0;
            write_offset_counter <= 7'd0;
            lvds_fifo_rd_en = 1'b0;
            frame_done <= 1'b0;
            blanking <= 1'b1;
            first_blank <= 1'b0;
        end else begin
            case (ddr3_w_state)
                DDR3_W_IDLE : begin
                    m_axi_hp0_awaddr     <= 32'h0010_0000;
                    m_axi_hp0_awvalid    <= 1'b0;
                    ram_ready <= ram_ready;
                    image_ready <= image_ready;
                    if(output_buffer_id != output_buffer_id_last && !ram_ready) begin
                        output_buffer_switch <= 1'b0;
                        ram_ready <= 1'b1;
                    end
                    if (new_frame_rdy) begin
                        image_ready <= 1'b1;
                    end
                    if (image_ready && ram_ready) begin
                        ddr3_w_state <= DDR3_W_ADDR_WRITE;
                        ram_ready <= 1'b0;
                        image_ready <= 1'b0;
                        if (blanking) write_offset <= (output_buffer_id ? FB2_OFFSET : FB1_OFFSET);
                        else write_offset <= (output_buffer_id ? FB2_RES_OFFSET : FB1_RES_OFFSET);
                        lvds_fifo_rd_en = 1'b1; //blocking
                    end
                end
                DDR3_W_ADDR_WRITE : begin
                    if (!awdone) begin
                        m_axi_hp0_awaddr  <= (write_counter << 3) + write_offset;
                        m_axi_hp0_awvalid <= 1'b1;
                    end
                    if(m_axi_hp0_awready && m_axi_hp0_awvalid) begin
                        m_axi_hp0_awaddr  <= '0;
                        m_axi_hp0_awvalid <= 1'b0;
                        awdone <= 1'b1;
                    end
                    if (blanking) begin
                        if (!wdone) begin
                            m_axi_hp0_wdata  <= 64'd0;
                            m_axi_hp0_wvalid <= 1'b1;
                        end
                    end else if (lvds_fifo_rd_valid && !wdone) begin
                        m_axi_hp0_wdata  <= lvds_fifo_rd_data;
                        m_axi_hp0_wvalid <= 1'b1;
                        lvds_fifo_rd_en = 1'b0;
                    end
                    if(m_axi_hp0_wready && m_axi_hp0_wvalid) begin
                        m_axi_hp0_wdata   <= '0;
                        m_axi_hp0_wvalid  <= 1'b0;
                        
                        wdone <= 1'b1;
                    end
                    if ((m_axi_hp0_awready && m_axi_hp0_awvalid && m_axi_hp0_wready && m_axi_hp0_wvalid) || 
                        (m_axi_hp0_awready && m_axi_hp0_awvalid && wdone) ||
                        (awdone && m_axi_hp0_wready && m_axi_hp0_wvalid)) begin
                        wdone <= 1'b0;
                        awdone <= 1'b0;
                        write_counter <= write_counter + 1;
                        if (!blanking && (res_vga || res_256)) begin
                            if (write_offset_counter == res_count_max) begin
                                if (res_vga) write_counter <= write_counter + 32'd81;
                                else write_counter <= write_counter + 32'd129;
                                write_offset_counter <= 7'd0;
                            end else begin 
                                write_offset_counter <= write_offset_counter + 7'd1;
                            end
                        end
                        if (write_counter == write_count_reset) begin
                            write_counter    <= '0;
                            write_offset_counter <= 7'd0;
                            ddr3_w_state     <=  DDR3_W_IDLE;
                            frame_done <= 1'b1;
                            output_buffer_switch <= 1'b1;
                            if (blanking) begin
                                first_blank <= 1'b1;
                                if (first_blank) blanking <= 1'b0;
                            end
                            lvds_fifo_rd_en = 1'b0;
                        end else lvds_fifo_rd_en = 1'b1;
                    end
                end
            endcase
        end
    end
    
    //counter for fps calc, counts every other frame
    logic [31:0] fps_counter;
    logic fps_count_buf;
    //how many clock cycles it takes for a single frame
    always_ff @ (posedge LVDS_INTERFACE_CLK) begin
        if (reset) begin
            fps_counter <= 32'd0;
            fps_stored_count <= 32'd0;
            fps_count_buf <= 1'b0;
        end else begin
            fps_stored_count <= fps_stored_count;
            fps_count_buf <= fps_count;
            fps_counter <= fps_counter;
            if (fps_count) fps_counter <= fps_counter + 32'd1;
            else if (!fps_count && fps_count_buf) begin
                fps_stored_count <= fps_counter;
                fps_counter <= 32'd0;
            end
        end
    end
    
    //storage state machine
    typedef enum logic {
        DDR3_W_STORE_IDLE,
        DDR3_W_STORE_WRITE
    } ddr3_w_store_state_t;
        
    ddr3_w_store_state_t ddr3_w_store_state;
    
    logic awdone_storage, wdone_storage, done_once, done;
    logic store_button_record, store_button_take_pic, start_recording_buf, start_taking_pic_buf, end_continuous_rec;
    
    logic [17:0] frame_counter;
    
    always_ff @ (posedge pixel_clk) begin
        if (rst_block) begin
            ddr3_w_store_state <= DDR3_W_STORE_IDLE;

            m_axi_hp1_awaddr  <= 32'h0000_0000;
            m_axi_hp1_awvalid <= 1'b0;

            m_axi_hp1_wdata  <= '0;
            m_axi_hp1_wvalid <= 1'b0;
            
            //////////////////////////////////////////
            recording <= 1'b0;
            write_storage_counter <= '0;
            lvds_fifo_rd_en_1 = 1'b0;
            awdone_storage <= 1'b0;
            wdone_storage <= 1'b0;
            end_continuous_rec <= 1'b0;
            continuous_store_start <= '0;
            frame_counter <= 18'd0;
            done_once <= 1'b0;
            done <= 1'b0;
        end else begin
            case (ddr3_w_store_state)
                DDR3_W_STORE_IDLE : begin
                    m_axi_hp1_awaddr     <= 32'h0010_0000;
                    m_axi_hp1_awvalid    <= 1'b0;
                    recording <= 1'b0;
                    done <= 1'b0; //i think done will safely be set low -> en_store_write set low before next image_ready
                    frame_counter <= 18'd0;
                    if (image_ready && en_store_write) begin
                        if (store_button_record) begin
                            recording <= 1'b1;
                        end else if (store_button_take_pic) begin
                            recording <= 1'b0;
                        end
                        ddr3_w_store_state <= DDR3_W_STORE_WRITE;
                        lvds_fifo_rd_en_1 = 1'b1; //blocking
                    end
                end
                DDR3_W_STORE_WRITE : begin
                    if (!continuous_rec) end_continuous_rec <= 1'b1;
                    if (!awdone_storage) begin
                        m_axi_hp1_awaddr  <= (write_storage_counter << 3) + STORAGE_OFFSET;
                        m_axi_hp1_awvalid <= 1'b1;
                    end
                    if(m_axi_hp1_awready && m_axi_hp1_awvalid) begin
                        m_axi_hp1_awaddr  <= '0;
                        m_axi_hp1_awvalid <= 1'b0;
                        awdone_storage <= 1'b1;
                    end
                    if (lvds_fifo_rd_valid_1 && !wdone_storage) begin
                        m_axi_hp1_wdata  <= lvds_fifo_rd_data_1;
                        m_axi_hp1_wvalid <= 1'b1;
                        lvds_fifo_rd_en_1 = 1'b0;
                    end
                    if(m_axi_hp1_wready && m_axi_hp1_wvalid) begin
                        m_axi_hp1_wdata   <= '0;
                        m_axi_hp1_wvalid  <= 1'b0;
                        
                        wdone_storage <= 1'b1;
                    end
                    if ((m_axi_hp1_awready && m_axi_hp1_awvalid && m_axi_hp1_wready && m_axi_hp1_wvalid) || 
                        (m_axi_hp1_awready && m_axi_hp1_awvalid && wdone_storage) ||
                        (awdone_storage && m_axi_hp1_wready && m_axi_hp1_wvalid)) begin
                        wdone_storage <= 1'b0;
                        awdone_storage <= 1'b0;
                        write_storage_counter <= write_storage_counter + 1;
                        if (frame_counter == frame_count_max) frame_counter <= 18'd0;
                        else frame_counter <= frame_counter + 1;
                        if ((write_storage_counter == write_count_storage_reset) || (end_continuous_rec && done_once && (frame_counter == frame_count_max))) begin
                            continuous_store_start <= write_storage_counter;
                            write_storage_counter    <= '0;
                            done_once <= 1'b1;
                            if (!continuous_rec) begin
                                ddr3_w_store_state     <=  DDR3_W_STORE_IDLE;
                                end_continuous_rec <= 1'b0;
                                done_once <= 1'b0;
                                done <= 1'b1;
                                recording <= 1'b0;
                                lvds_fifo_rd_en_1 = 1'b0;
                            end else lvds_fifo_rd_en_1 = 1'b1;
                        end else lvds_fifo_rd_en_1 = 1'b1;
                    end
                end
            endcase
        end
    end
    
    always_ff @ (posedge pixel_clk) begin
        if (reset) begin
            store_button_record <= 1'b0;
            store_button_take_pic <= 1'b0;
            start_recording_buf <= 1'b0;
            start_taking_pic_buf <= 1'b0;
        end else begin
            start_recording_buf <= start_recording;
            start_taking_pic_buf <= start_taking_pic;
            if (!storing) begin
                if (!store_button_take_pic && start_recording && !start_recording_buf) store_button_record <= 1'b1;
                else if (!store_button_record && start_taking_pic && !start_taking_pic_buf) store_button_take_pic <= 1'b1;
                if (done) begin
                    store_button_record <= 1'b0;
                    store_button_take_pic <= 1'b0;
                end
            end
        end
    end
        
    always_ff @ (posedge pixel_clk) begin
        if (reset) begin
            en_store_write <= 1'b0;
            PL_VID_STORE_START <= 1'b0;
            PL_PIC_STORE_START <= 1'b0;
        end else begin
            en_store_write <= en_store_write;
            PL_PIC_STORE_START <= PL_PIC_STORE_START;
            PL_VID_STORE_START <= PL_VID_STORE_START;
            if (!storing) begin
                //can take pics/video (recording)
                if (write_to_lvds_fifo && ram_ready && (store_button_record || store_button_take_pic)) en_store_write <= 1'b1;
                if (done) en_store_write <= 1'b0;
            end else begin
                //ignore attempts to record, just signal PS to store
                if (start_recording && !start_recording_buf && !PL_PIC_STORE_START) PL_VID_STORE_START <= 1'b1; //recording takes precedence if both buttons pressed same time
                else if (start_taking_pic && !start_taking_pic_buf && !PL_VID_STORE_START) PL_PIC_STORE_START <= 1'b1;
                if (PS_VID_STORING) PL_VID_STORE_START <= 1'b0;
                if (PS_PIC_STORING) PL_PIC_STORE_START <= 1'b0;
            end
        end
    end
    
    /* Tie m_axi_hp1 AR and R channels to 0 */
    always_ff @(posedge pixel_clk) begin
        if (reset) begin
            m_axi_hp1_araddr  <= 32'h0000_0000;
            m_axi_hp1_arvalid <= 1'b0;

            m_axi_hp1_rdata  <= '0;
            m_axi_hp1_rvalid <= 1'b0;
            
        end else begin
            m_axi_hp1_araddr  <= 32'h0000_0000;
            m_axi_hp1_arvalid <= 1'b0;

            m_axi_hp1_rdata  <= '0;
            m_axi_hp1_rvalid <= 1'b0;
            
        end
    end
    
    assign m_axi_hp0_bready    = 1'b1;
    assign m_axi_hp1_bready    = 1'b1;
    assign m_axi_hp0_rready    = !pixel_fifo_full && m_axi_hp0_rvalid;// && read_ready;
    assign pixel_fifo_write_en = !pixel_fifo_full && m_axi_hp0_rvalid;// && read_ready;
    assign pixel_fifo_din      = m_axi_hp0_rdata;
    
    assign VGA_RED_O = VGA_RED_O_long[9:6];
    assign VGA_GREEN_O = VGA_GREEN_O_long[9:6];
    assign VGA_BLUE_O = VGA_BLUE_O_long[9:6];
    logic oVGA_ACTIVE;
    
    logic [2:0] pixel_counter;
    logic delay_1;
    
    // FIFO Reader
    always_ff @ (posedge pixel_clk) begin
        if (reset) begin
            pixel_fifo_read_en <= 1'b0;
            temp_data          <= '0;

            VGA_red <= '0;
            VGA_green <= '0;
            VGA_blue <= '0;
            
            delay_1 <= 1'b0;
            pixel_counter <= 3'd0;
        end else begin
            pixel_fifo_read_en <= 1'b0;
            if (colour_mode) begin
                
                if (temp_data[7]) begin
                    VGA_red     <= 10'b1111111111;
                    VGA_green   <= {temp_data[6:3], 6'd0};
                    VGA_blue    <= 10'b1111111111;            
                end else begin
                    VGA_red     <= {temp_data[6:3], 6'b00};
                    VGA_green   <= 10'd0;
                    VGA_blue    <= {temp_data[6:3], 6'b00};
                end
            end else begin
                VGA_red     <= {temp_data[7:0], 2'd0};
                VGA_green   <= {temp_data[7:0], 2'd0};
                VGA_blue    <= {temp_data[7:0], 2'd0};
            end
            if (pixel_counter == 3'd0) begin
                if (oVGA_ACTIVE) begin
                    if (delay_1 == 1'b0) begin
                        delay_1 <= 1'b1;
                        pixel_counter <= pixel_counter + 3'd1;
                    end else begin
                        pixel_fifo_read_en <= 1'b1;
                        temp_data          <= pixel_fifo_dout;
                        pixel_counter <= pixel_counter + 3'd1;
                    end
                end
            end else begin
                temp_data <= {8'd0, temp_data[63:8]}; //{temp_data[55:0], 8'd0};
                pixel_counter <= pixel_counter + 3'd1;
            end
        end
    end
        
    fifo # (
        .ADDR_WIDTH(5 ),
        .DATA_WIDTH(64)
    ) pixel_fifo_inst (
        .clk     (pixel_clk          ), // Input
        .reset   (reset              ), // Input
        .write_en(pixel_fifo_write_en), // Input
        .read_en (pixel_fifo_read_en ), // Input
        .din     (pixel_fifo_din     ), // Input  [63:0]
        .empty   (pixel_fifo_empty   ), // Output
        .full    (pixel_fifo_full    ), // Output
        .dout    (pixel_fifo_dout    ), // Output [63:0]
        .level   (pixel_fifo_level   )  // Output [ 4:0]
    );
    
    // VGA unit
    VGA_Controller VGA_unit(
        .Clock(pixel_clk),
        .reset(reset),
    
        .iRed(VGA_red),
        .iGreen(VGA_green),
        .iBlue(VGA_blue),
        //.oCoord_X(pixel_X_pos),
        //.oCoord_Y(pixel_Y_pos),
        
        //    VGA Side
        .oVGA_R(VGA_RED_O_long),
        .oVGA_G(VGA_GREEN_O_long),
        .oVGA_B(VGA_BLUE_O_long),
        .oVGA_H_SYNC(VGA_HSYNC_O),
        .oVGA_V_SYNC(VGA_VSYNC_O),
        //.oVGA_SYNC(VGA_SYNC_O),
        .oVGA_ACTIVE(oVGA_ACTIVE)
        //.oVGA_CLOCK(VGA_CLOCK_O)
    );
        
    zynq_wrapper zynq_block_inst (
    
        .aux_reset_in_0     (&reset_sync                         ), // input
        .dcm_locked_0       (plls_locked                         ),
        
        .periph_reset       (reset                               ), // output [ 0:0]
        // AXI HP0 Slave Port
        .S_AXI_HP0_0_araddr (m_axi_hp0_araddr                    ), // Input  [31:0]
        .S_AXI_HP0_0_arburst(2'b01                               ), // Input  [ 1:0]
        .S_AXI_HP0_0_arcache(4'b0000                             ), // Input  [ 3:0]
        .S_AXI_HP0_0_arlen  (4'd0                                ), // Input  [ 3:0]
        .S_AXI_HP0_0_arid   (6'd0                                ), // Input  [ 5:0]
        .S_AXI_HP0_0_arlock (2'd0                                ), // Input  [ 1:0]
        .S_AXI_HP0_0_arprot (3'b000                              ), // Input  [ 2:0]
        .S_AXI_HP0_0_arqos  (4'd0                                ), // Input  [ 3:0]
        .S_AXI_HP0_0_arready(m_axi_hp0_arready                   ), // Output
        .S_AXI_HP0_0_arsize (3'b011                              ), // Input  [ 2:0]
        .S_AXI_HP0_0_arvalid(m_axi_hp0_arvalid                   ), // Input
        .S_AXI_HP0_0_awaddr (m_axi_hp0_awaddr                    ), // Input  [31:0]
        .S_AXI_HP0_0_awburst(2'b01                               ), // Input  [ 1:0]
        .S_AXI_HP0_0_awcache(4'b0000                             ), // Input  [ 3:0]
        .S_AXI_HP0_0_awid   (6'd0                                ), // Input  [ 5:0]
        .S_AXI_HP0_0_awlen  (4'd0                                ), // Input  [ 3:0]
        .S_AXI_HP0_0_awlock (2'd0                                ), // Input  [ 1:0]
        .S_AXI_HP0_0_awprot (3'b000                              ), // Input  [ 2:0]
        .S_AXI_HP0_0_awqos  (4'd0                                ), // Input  [ 3:0]
        .S_AXI_HP0_0_awready(m_axi_hp0_awready                   ), // Output
        .S_AXI_HP0_0_awsize (3'b011                              ), // Input  [ 2:0]
        .S_AXI_HP0_0_awvalid(m_axi_hp0_awvalid                   ), // Input  [ 0:0]
        .S_AXI_HP0_0_bid    (                                    ), // Output [ 5:0]
        .S_AXI_HP0_0_bready (m_axi_hp0_bready && m_axi_hp0_bvalid), // Input
        .S_AXI_HP0_0_bresp  (m_axi_hp0_bresp                     ), // Output [ 1:0]
        .S_AXI_HP0_0_bvalid (m_axi_hp0_bvalid                    ), // Output
        .S_AXI_HP0_0_rdata  (m_axi_hp0_rdata                     ), // Output [63:0]
        .S_AXI_HP0_0_rid    (                                    ), // Output [ 5:0]
        .S_AXI_HP0_0_rlast  (                                    ), // Output
        .S_AXI_HP0_0_rready (m_axi_hp0_rready && m_axi_hp0_rvalid), // Input
        .S_AXI_HP0_0_rresp  (                                    ), // Output [ 1:0]
        .S_AXI_HP0_0_rvalid (m_axi_hp0_rvalid                    ), // Output
        .S_AXI_HP0_0_wdata  (m_axi_hp0_wdata                     ), // Input  [63:0]
        .S_AXI_HP0_0_wid    (6'd0                                ), // Input  [ 5:0]
        .S_AXI_HP0_0_wlast  (1'b1                                ), // Input
        .S_AXI_HP0_0_wready (m_axi_hp0_wready                    ), // Output
        .S_AXI_HP0_0_wstrb  (8'hFF                               ), // Input  [ 7:0]
        .S_AXI_HP0_0_wvalid (m_axi_hp0_wvalid                    ), // Input
        
        // AXI HP1 Slave Port
        .S_AXI_HP1_0_araddr (m_axi_hp1_araddr                    ), // Input  [31:0]
        .S_AXI_HP1_0_arburst(2'b01                               ), // Input  [ 1:0]
        .S_AXI_HP1_0_arcache(4'b0000                             ), // Input  [ 3:0]
        .S_AXI_HP1_0_arlen  (4'd0                                ), // Input  [ 3:0]
        .S_AXI_HP1_0_arid   (6'd0                                ), // Input  [ 5:0]
        .S_AXI_HP1_0_arlock (2'd0                                ), // Input  [ 1:0]
        .S_AXI_HP1_0_arprot (3'b000                              ), // Input  [ 2:0]
        .S_AXI_HP1_0_arqos  (4'd0                                ), // Input  [ 3:0]
        .S_AXI_HP1_0_arready(m_axi_hp1_arready                   ), // Output
        .S_AXI_HP1_0_arsize (3'b011                              ), // Input  [ 2:0]
        .S_AXI_HP1_0_arvalid(m_axi_hp1_arvalid                   ), // Input
        .S_AXI_HP1_0_awaddr (m_axi_hp1_awaddr                    ), // Input  [31:0]
        .S_AXI_HP1_0_awburst(2'b01                               ), // Input  [ 1:0]
        .S_AXI_HP1_0_awcache(4'b0000                             ), // Input  [ 3:0]
        .S_AXI_HP1_0_awid   (6'd0                                ), // Input  [ 5:0]
        .S_AXI_HP1_0_awlen  (4'd0                                ), // Input  [ 3:0]
        .S_AXI_HP1_0_awlock (2'd0                                ), // Input  [ 1:0]
        .S_AXI_HP1_0_awprot (3'b000                              ), // Input  [ 2:0]
        .S_AXI_HP1_0_awqos  (4'd0                                ), // Input  [ 3:0]
        .S_AXI_HP1_0_awready(m_axi_hp1_awready                   ), // Output
        .S_AXI_HP1_0_awsize (3'b011                              ), // Input  [ 2:0]
        .S_AXI_HP1_0_awvalid(m_axi_hp1_awvalid                   ), // Input  [ 0:0]
        .S_AXI_HP1_0_bid    (                                    ), // Output [ 5:0]
        .S_AXI_HP1_0_bready (m_axi_hp1_bready && m_axi_hp1_bvalid), // Input
        .S_AXI_HP1_0_bresp  (m_axi_hp1_bresp                     ), // Output [ 1:0]
        .S_AXI_HP1_0_bvalid (m_axi_hp1_bvalid                    ), // Output
        .S_AXI_HP1_0_rdata  (m_axi_hp1_rdata                     ), // Output [63:0]
        .S_AXI_HP1_0_rid    (                                    ), // Output [ 5:0]
        .S_AXI_HP1_0_rlast  (                                    ), // Output
        .S_AXI_HP1_0_rready (m_axi_hp1_rready && m_axi_hp1_rvalid), // Input
        .S_AXI_HP1_0_rresp  (                                    ), // Output [ 1:0]
        .S_AXI_HP1_0_rvalid (m_axi_hp1_rvalid                    ), // Output
        .S_AXI_HP1_0_wdata  (m_axi_hp1_wdata                     ), // Input  [63:0]
        .S_AXI_HP1_0_wid    (6'd0                                ), // Input  [ 5:0]
        .S_AXI_HP1_0_wlast  (1'b1                                ), // Input
        .S_AXI_HP1_0_wready (m_axi_hp1_wready                    ), // Output
        .S_AXI_HP1_0_wstrb  (8'hFF                               ), // Input  [ 7:0]
        .S_AXI_HP1_0_wvalid (m_axi_hp1_wvalid                    ), // Input
        
        .DDR_addr         (DDR_addr                            ),
        .DDR_ba           (DDR_ba                              ),
        .DDR_cas_n        (DDR_cas_n                           ),
        .DDR_ck_n         (DDR_ck_n                            ),
        .DDR_ck_p         (DDR_ck_p                            ),
        .DDR_cke          (DDR_cke                             ),
        .DDR_cs_n         (DDR_cs_n                            ),
        .DDR_dm           (DDR_dm                              ),
        .DDR_dq           (DDR_dq                              ),
        .DDR_dqs_n        (DDR_dqs_n                           ),
        .DDR_dqs_p        (DDR_dqs_p                           ),
        .DDR_odt          (DDR_odt                             ),
        .DDR_ras_n        (DDR_ras_n                           ),
        .DDR_reset_n      (DDR_reset_n                         ),
        .DDR_we_n         (DDR_we_n                            ),
        .FIXED_IO_ddr_vrn (FIXED_IO_ddr_vrn                    ),
        .FIXED_IO_ddr_vrp (FIXED_IO_ddr_vrp                    ),
        .FIXED_IO_mio     (FIXED_IO_mio                        ),
        .FIXED_IO_ps_clk  (FIXED_IO_ps_clk                     ),
        .FIXED_IO_ps_porb (FIXED_IO_ps_porb                    ),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb                   ),
        
        .FIFO_READ_0_empty(lvds_fifo_empty                     ),
        .FIFO_READ_0_rd_data(lvds_fifo_rd_data                 ),
        .FIFO_READ_0_rd_en(lvds_fifo_rd_en                     ),
        .valid_0(lvds_fifo_rd_valid                            ),
        .FIFO_WRITE_0_full(lvds_fifo_full                      ),
        .FIFO_WRITE_0_wr_data(lvds_fifo_wr_data                ),
        .FIFO_WRITE_0_wr_en(lvds_fifo_wr_en                    ),
        .wr_clk_0(LVDS_INTERFACE_CLK                           ),
        .fifo_reset(sync_reset                                 ),
        
        .FIFO_READ_1_empty(lvds_fifo_empty_1                   ),
        .FIFO_READ_1_rd_data(lvds_fifo_rd_data_1               ),
        .FIFO_READ_1_rd_en(lvds_fifo_rd_en_1                   ),
        .valid_1(lvds_fifo_rd_valid_1                          ),
        .FIFO_WRITE_1_full(lvds_fifo_full_1                    ),
        .FIFO_WRITE_1_wr_data(lvds_fifo_wr_data_1              ),
        .FIFO_WRITE_1_wr_en(lvds_fifo_wr_en_1                  ),
        .wr_clk_1(LVDS_INTERFACE_CLK                           ),
        .fifo_reset_1(sync_reset                               ),
        
        .PL_TO_PS_0       (PL_TO_PS_0                          ),
        .PL_TO_PS_1       (PL_TO_PS_1                          ),
        .PL_TO_PS_2       (PL_TO_PS_2                          ),
        .PS_TO_PL_0       (PS_TO_PL                            ),
        
        //.ila_clk          (ila_clk                             ),
        .logic_clk        (logic_clk                           ),
        .pixel_clk        (pixel_clk                           ),
        .logic_clk_pll_locked(logic_clk_pll_locked             ),
        .pixel_clk_pll_locked(pixel_clk_pll_locked             ),
        .ref_clk          (refclkin                            ),
        .ref_clk_pll_locked(ref_clk_pll_locked                 ),
        .pll_resets       (~zynq_resetn                        ),
        .resetn           (zynq_resetn                         )
    );
    /*
    ila_0 ila_0_inst (
        .clk   (pixel_clk              ),
        .probe0(HFRC_state             ), //4
        .probe1(ddr3_w_state           ), //2
        .probe2(lvds_fifo_rd_valid     ), 
        .probe3(lvds_fifo_rd_en        ),
        .probe4(lvds_fifo_empty        ),
        .probe5(m_axi_hp0_wdata        ), //64
        .probe6(m_axi_hp0_wvalid       ),
        .probe7(m_axi_hp0_wready       ),
        .probe8(m_axi_hp0_awaddr       ), //32
        .probe9(m_axi_hp0_awvalid      ),
        .probe10(m_axi_hp0_awready     ),
        .probe11(select_pixel          ), //2:0
        .probe12(VGA_RED_O             ), //3:0
        .probe13(oVGA_ACTIVE           ),
        .probe14(blanking              ), //10:0 -> 1 
        .probe15(res_vga               ), //2 //10:0
        .probe16(image_ready           ),
        .probe17(ram_ready             ),
        .probe18(write_counter         ),  //31:0
        
        .probe19(LVDS_state            ), //3
        .probe20(RAM_DATA_RDY          ),
        .probe21(new_frame_rdy         ),
        .probe22(data_is_aligned       ),
        .probe23(num_of_lines          ), //20
        .probe24(CHANGE_BITSLIP        ), //
        .probe25(bitslip_state         ),  //3
        
        .probe26(lvds_fifo_full         ),
        .probe27(write_to_lvds_fifo     ),
        //.probe7(lvds_fifo_wr_data      ), //64
        .probe28(lvds_fifo_wr_en        ),
        .probe29(SYNC_DATA              ), //9:0
        
        .probe30(output_buffer_id                ),
        .probe31(output_buffer_switch_triggered  ),
        .probe32(read_counter                    ), //32
        .probe33(frame_done                      ),
        .probe34(pixel_fifo_write_en),
        .probe35(pixel_fifo_full),
        .probe36(m_axi_hp0_rvalid),
        .probe37(m_axi_hp1_rready),
        .probe38(m_axi_hp0_araddr), //32
        .probe39(m_axi_hp0_arready),
        .probe40(m_axi_hp0_arvalid)
    );
    */
    /*
    ila_1 ila_1_inst (
        .clk   (logic_clk              ),
        .probe0(tag_state              ), //2
        .probe1(bram_dina              ), //64
        .probe2(bram_doutb             ), //64        
        .probe3(bram_addra             ), //4
        .probe4(bram_addrb             ), //4
        .probe5(bram_wea               ), //1
        .probe6(tag_count              ), //10
        .probe7(lvds_fifo_wr_en_1      ), //1
        .probe8(wtag_state             ), //1
        .probe9(lvds_fifo_wr_data_1    ), //64
        .probe10(reading_tags          )  //1
    );
    */
endmodule
