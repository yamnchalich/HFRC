/*
LVDS Interface between HFRC and FPGA through FMC
By: Yamn Chalich
*/

`timescale 1ns/100ps

module LVDS_Interface (
				
		input logic  CLK,						// LVDS slow clk
		//input logic test_clk,
		input logic  sync_reset,
		input logic  monitor_0,    //integration time, check for falling edge
		// LVDS data_in
		input logic  [9:0] SYNC_DATA_IN,
		input logic  [9:0] D3_DATA_IN,
		input logic  [9:0] D2_DATA_IN,
		input logic  [9:0] D1_DATA_IN,
	    input logic  [9:0] D0_DATA_IN,
		input logic frame_buffer_rdy,
		
		output logic new_frame_rdy,
		output logic write_to_lvds_fifo,
		output logic wait_30_fps,
		output logic [63:0] RAM_DATA,
		output logic RAM_DATA_RDY,
		output logic bitslip,
		output logic fps_count,
		
		output logic data_aligned,
		output logic [2:0] lvds_state_o,
		output logic [19:0] num_lines,
		output logic [2:0] bitslip_state_o
);

logic bitslip_change;
assign bitslip = bitslip_change;

logic [2:0] FS, FE, LS, LE;
logic [6:0] FRAME_SYNC_CODE;
logic [9:0] BL, IMG, CRC, TR;

logic data_rdy;
assign RAM_DATA_RDY = data_rdy;
logic [63:0] RAM_DATA_IN;
logic [31:0] BUFFER;
logic [19:0] num_of_frames, num_of_lines;

assign num_lines = num_of_lines;

assign RAM_DATA = RAM_DATA_IN;

assign FS = 3'h5;										//frame start
assign FE = 3'h6;										//frame end
assign LS = 3'h1;										//line start
assign LE = 3'h2;										//line end
assign FRAME_SYNC_CODE = 7'h2A;					        //indicates frame sync code 

assign BL = 10'h015;									//black pixel data
assign IMG = 10'h035;                                   //image data
assign CRC = 10'h059;								    //CRC data
assign TR = 10'h3A6;									//training data

enum logic [2:0] {
	S_IDLE,
	S_READ_FRAME_START,
	S_READ_LINE_START,
	S_READ_ID,
	S_READ_IMAGE,
	S_READ_ID_FE,
	S_READ_ID_LE
} LVDS_state;

assign lvds_state_o = LVDS_state;

enum logic [2:0] {
	S_KERNEL_EVEN_0,
	S_KERNEL_EVEN_1,
	S_KERNEL_ODD_0,
	S_KERNEL_ODD_1
} READ_IMAGE_state;


//data alignment before starting receiver
logic ENABLE_LVDS_RECEIVER, ENABLE_BITSLIP;
logic integration_time, integration_time_buf;
logic bitslip_change_sync;

always_ff @ (posedge CLK) begin
    if (sync_reset) begin
        ENABLE_BITSLIP <= 1'b0;
        integration_time <= 1'b0;
        integration_time_buf <= 1'b0;
    end else begin
        integration_time <= monitor_0;
        integration_time_buf <= integration_time;
        ENABLE_BITSLIP <= 1'b0;
        if (integration_time == 1'b0 && integration_time_buf == 1'b1) 
            ENABLE_BITSLIP <= 1'b1;
    end
end

logic [9:0] prev_sync_data;
logic [2:0] bitslip_state;

assign bitslip_state_o = bitslip_state;

always_ff @ (posedge CLK) begin
    if (sync_reset) begin
        ENABLE_LVDS_RECEIVER <= 1'b0;
        bitslip_state <= 3'd0;
        bitslip_change <= 1'b0;
        prev_sync_data <= 10'd0;
    end else begin
        bitslip_change <= 1'b0;
        ENABLE_LVDS_RECEIVER <= ENABLE_LVDS_RECEIVER;
        case (bitslip_state)
        3'd0: begin
            if (ENABLE_BITSLIP) begin //falling edge of MONITOR_0
                bitslip_state <= 3'd1;
            end
        end
        3'd1: begin //CHECK
            bitslip_change <= 1'b0;
            if (SYNC_DATA_IN == TR) begin
                ENABLE_LVDS_RECEIVER <= 1'b1;
                bitslip_state <= 3'd3;
            end else begin
                bitslip_state <= 3'd2;
                bitslip_change <= 1'b1;
                prev_sync_data <= SYNC_DATA_IN;
            end
        end
        3'd2: begin //ISSUE BITSLIP
            bitslip_change <= 1'b0;
            if (SYNC_DATA_IN != prev_sync_data)
                bitslip_state <= 3'd1; //bitslip change occurred, move on to check again
        end
        3'd3: begin
            bitslip_state <= 3'd3;
        end
        endcase
    end
end

logic data_is_aligned;
assign data_aligned = data_is_aligned;

logic write_to_fifo;
assign write_to_lvds_fifo = write_to_fifo;

logic new_frame_ready;
assign new_frame_rdy = new_frame_ready;

logic wait_for_30_fps;
assign wait_30_fps = wait_for_30_fps;

logic fps_count_flip;
assign fps_count = fps_count_flip;

logic on_return;

always_ff @(posedge CLK) begin
	if (sync_reset) begin
		num_of_frames <= 20'd0;
		num_of_lines <= 20'd0;
		data_rdy <= 1'b0;
		data_is_aligned <= 1'b0;
		BUFFER <= 32'd0;
		RAM_DATA_IN <= 64'd0;
		LVDS_state <= S_IDLE;
		READ_IMAGE_state <= S_KERNEL_ODD_0;
		write_to_fifo <= 1'b0;
		new_frame_ready <= 1'b0;
		on_return <= 1'b0;
		fps_count_flip <= 1'b0;
		wait_for_30_fps <= 1'b0;
	end else begin
		case (LVDS_state)
		S_IDLE: begin
			if (ENABLE_LVDS_RECEIVER) begin
				LVDS_state <= S_READ_FRAME_START;
				data_is_aligned <= 1'b1;
			end
		end
		S_READ_FRAME_START: begin
            if (on_return) begin
                //RAM_DATA_IN <= {RAM_DATA_IN[31:0], BUFFER};
                RAM_DATA_IN <= {BUFFER, RAM_DATA_IN[31:0]};
                data_rdy <= 1'b1;
                on_return <= 1'b0;
            end else begin
                data_rdy <= 1'b0;
                BUFFER <= 32'd0;
                RAM_DATA_IN <= 64'd0;
            end
			if (SYNC_DATA_IN == {FS, FRAME_SYNC_CODE}) begin
                num_of_frames <= num_of_frames + 20'd1;
                num_of_lines <= 20'd0;
                LVDS_state <= S_READ_ID;
                fps_count_flip <= ~fps_count_flip;
                
                if (frame_buffer_rdy) begin
                    write_to_fifo <= 1'b1;
                    wait_for_30_fps <= ~wait_for_30_fps;
                end else write_to_fifo <= 1'b0;
                //				6				4				2				0
                BUFFER <= {D3_DATA_IN[9:2], D2_DATA_IN[9:2], D1_DATA_IN[9:2], D0_DATA_IN[9:2]};
			end
		end
		S_READ_LINE_START: begin
            if (on_return) begin
                //RAM_DATA_IN <= {RAM_DATA_IN[31:0], BUFFER};
                RAM_DATA_IN <= {BUFFER, RAM_DATA_IN[31:0]};
                data_rdy <= 1'b1;
                on_return <= 1'b0;
            end else begin
                data_rdy <= 1'b0;
                BUFFER <= 32'd0;
                RAM_DATA_IN <= 64'd0;
            end
            if (SYNC_DATA_IN == {LS, FRAME_SYNC_CODE}) begin
               num_of_lines <= num_of_lines + 20'd1;
               LVDS_state <= S_READ_ID;
               //				6				4				2				0
               BUFFER <= {D3_DATA_IN[9:2], D2_DATA_IN[9:2], D1_DATA_IN[9:2], D0_DATA_IN[9:2]};
           end
		end
		S_READ_ID: begin
            data_rdy <= 1'b0;
			LVDS_state <= S_READ_IMAGE;
            BUFFER <= {D3_DATA_IN[9:2], BUFFER[31:24], D2_DATA_IN[9:2], BUFFER[23:16]};
            //                   null                 3             2             1               0
            RAM_DATA_IN <= {RAM_DATA_IN[31:0], D1_DATA_IN[9:2], BUFFER[15:8], D0_DATA_IN[9:2], BUFFER[7:0]};
		end
		S_READ_IMAGE: begin
			data_rdy <= 1'b0;
			
			if (READ_IMAGE_state == S_KERNEL_EVEN_0) begin
                //				6				4				2				0
                BUFFER <= {D3_DATA_IN[9:2], D2_DATA_IN[9:2], D1_DATA_IN[9:2], D0_DATA_IN[9:2]};
                RAM_DATA_IN <= {BUFFER, RAM_DATA_IN[31:0]};
                
                data_rdy <= 1'b1;
                
                //issue the frame buffer that the fifo is ready to start reading from
                if (frame_buffer_rdy && write_to_fifo) new_frame_ready <= 1'b1;
                else new_frame_ready <= 1'b0;
                
                READ_IMAGE_state <= S_KERNEL_EVEN_1;
                
            end else if (READ_IMAGE_state == S_KERNEL_EVEN_1) begin
            		
				BUFFER <= {D3_DATA_IN[9:2], BUFFER[31:24], D2_DATA_IN[9:2], BUFFER[23:16]};
				//                   null                 3             2             1               0
                RAM_DATA_IN <= {RAM_DATA_IN[31:0], D1_DATA_IN[9:2], BUFFER[15:8], D0_DATA_IN[9:2], BUFFER[7:0]};
            
				data_rdy <= 1'b0;
				READ_IMAGE_state <= S_KERNEL_ODD_0;
				
			end else if (READ_IMAGE_state == S_KERNEL_ODD_0) begin
			    
				//				15				13				  11			  9
                BUFFER <= {D0_DATA_IN[9:2], D1_DATA_IN[9:2], D2_DATA_IN[9:2], D3_DATA_IN[9:2]};
                RAM_DATA_IN <= {BUFFER, RAM_DATA_IN[31:0]};
                
				data_rdy <= 1'b1;
				READ_IMAGE_state <= S_KERNEL_ODD_1;
				
			end else if (READ_IMAGE_state == S_KERNEL_ODD_1) begin	
				
				//              15             14            13            12
                BUFFER <= {BUFFER[31:24], D0_DATA_IN[9:2], BUFFER[23:16], D1_DATA_IN[9:2]};
                RAM_DATA_IN <= {RAM_DATA_IN[31:0], BUFFER[15:8], D2_DATA_IN[9:2], BUFFER[7:0], D3_DATA_IN[9:2]};
				
				data_rdy <= 1'b0;
				READ_IMAGE_state <= S_KERNEL_EVEN_0;
				
			end
			if (SYNC_DATA_IN == {LE, FRAME_SYNC_CODE}) begin
				LVDS_state <= S_READ_ID_LE;
				READ_IMAGE_state <= S_KERNEL_ODD_0;
			end
			if (SYNC_DATA_IN == {FE, FRAME_SYNC_CODE}) begin
                LVDS_state <= S_READ_ID_FE;
                READ_IMAGE_state <= S_KERNEL_ODD_0;
            end
		end
		S_READ_ID_FE: begin            
            
            //              15             14            13            12
            BUFFER <= {BUFFER[31:24], D0_DATA_IN[9:2], BUFFER[23:16], D1_DATA_IN[9:2]};
            RAM_DATA_IN <= {RAM_DATA_IN[31:0], BUFFER[15:8], D2_DATA_IN[9:2], BUFFER[7:0], D3_DATA_IN[9:2]};
                        
            data_rdy <= 1'b0;
            on_return <= 1'b1;
            LVDS_state <= S_READ_FRAME_START;
        end
        S_READ_ID_LE: begin            
            
            //              15             14            13            12
            BUFFER <= {BUFFER[31:24], D0_DATA_IN[9:2], BUFFER[23:16], D1_DATA_IN[9:2]};
            RAM_DATA_IN <= {RAM_DATA_IN[31:0], BUFFER[15:8], D2_DATA_IN[9:2], BUFFER[7:0], D3_DATA_IN[9:2]};
                        
            data_rdy <= 1'b0;
            
            on_return <= 1'b1;
            LVDS_state <= S_READ_LINE_START;
        end
		endcase
	end
end

endmodule
