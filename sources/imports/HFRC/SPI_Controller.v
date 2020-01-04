/*
This module controls the configuration 
interface of the PYTHON 1300 Image Sensor
By: Yamn Chalich
*/

`timescale 1ns/100ps
/*
`ifdef DISABLE_DEFAULT_NET
`else
`default_nettype none
`endif
*/

module SPI_Controller (
	input wire reset,
	input wire SPI_START,
	
	/////// SPI
	input wire SCK,									//Serial Clock
	output logic SS_N,								//Active Low Slave select
	
	output logic MOSI,								//Serial Data To Sensor
	input wire MISO,								//Serial Data From Sensor
	
	input wire [25:0] SPI_upload_data,
	output logic [15:0] SPI_read_data,
	output reg UPLOAD_DONE
);

enum logic [2:0] {
	SPI_IDLE,
	SPI_UPLOAD_ADDRESS,
	SPI_READ_DELAY,
	SPI_READ,
	SPI_WRITE,
	SPI_WRITE_DELAY,
	SPI_SLAVE_SELECT_UP,
	SPI_DELAY
} SPI_state;

logic [25:0] SPI_upload_shift_reg;
logic [4:0] serial_counter;


// SPI control state machine
always_ff @(negedge SCK) begin
	if (reset) begin
      SPI_state <= SPI_IDLE;
		SPI_upload_shift_reg <= 26'd0;
		SPI_read_data <= 16'd0;
		serial_counter <= 5'd0;
		UPLOAD_DONE <= 1'b0;
		SS_N <= 1'b1;
	end else begin
			case (SPI_state)
			SPI_IDLE: begin
				if (SPI_START) begin
					SPI_read_data <= 16'd0;
					SPI_state <= SPI_UPLOAD_ADDRESS;
					SPI_upload_shift_reg <= {SPI_upload_data[24:0], 1'b0};
					SS_N <= 1'b0;
					
					MOSI <= SPI_upload_data[25];
					serial_counter <= serial_counter + 5'd1;
				end
			end
			SPI_UPLOAD_ADDRESS: begin
				MOSI <= SPI_upload_shift_reg[25];
				SPI_upload_shift_reg <= {SPI_upload_shift_reg[24:0], 1'b0};
				serial_counter <= serial_counter + 5'd1;
				if (serial_counter == 5'd9) begin	
					if (SPI_upload_shift_reg[25])
						SPI_state <= SPI_WRITE;
					else
						SPI_state <= SPI_READ_DELAY;
				end
			end
			SPI_READ_DELAY: begin
				//wait for data to be available on miso pin
				SPI_state <= SPI_READ;
			end
			SPI_READ: begin
				SPI_read_data <= {SPI_read_data[14:0], MISO};
				serial_counter <= serial_counter + 5'd1;
				
				if (serial_counter == 5'd26) begin
				    SPI_read_data <= SPI_read_data;
					serial_counter <= 5'd0;
					SS_N <= 1'b1;
					UPLOAD_DONE <= 1'b1;
					SPI_state <= SPI_SLAVE_SELECT_UP;
				end
			end
			SPI_WRITE: begin
				MOSI <= SPI_upload_shift_reg[25];
				SPI_upload_shift_reg <= {SPI_upload_shift_reg[24:0], 1'b0};
				serial_counter <= serial_counter + 5'd1;
				if (serial_counter == 5'd26) begin
					serial_counter <= 5'd0;
					UPLOAD_DONE <= 1'b1;
					SS_N <= 1'b1;
					SPI_state <= SPI_SLAVE_SELECT_UP;
				end
			end
			SPI_SLAVE_SELECT_UP: begin
				//pull SS_N up one clock cycle after last bit transmission
				UPLOAD_DONE <= 1'b0;
				SPI_state <= SPI_DELAY;
			end
			SPI_DELAY: begin
                //give more time between spi uploads
                SPI_state <= SPI_IDLE;
            end
		endcase
	end
end
endmodule
