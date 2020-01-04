/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada

Slightly modified for the purpose of this project
-Yamn Chalich
*/

`timescale 1ns/100ps
//`default_nettype none

module VGA_Controller (
		input logic Clock,
		input logic reset,

		input logic [9:0] iRed,
		input logic [9:0] iGreen,
		input logic [9:0] iBlue,
		//output logic [10:0] oCoord_X,
		//output logic [10:0] oCoord_Y,
		
		//	VGA Side
		output logic [9:0] oVGA_R,
		output logic [9:0] oVGA_G,
		output logic [9:0] oVGA_B,
		output logic oVGA_H_SYNC,
		output logic oVGA_V_SYNC,
		//output logic oVGA_SYNC,
		output logic oVGA_ACTIVE
		//output logic oVGA_CLOCK
);

`include "VGA_Param.h"

logic [10:0] H_Cont;
logic [10:0] V_Cont;

logic [10:0] oCoord_X;
logic [10:0] oCoord_Y;

assign oVGA_ACTIVE = (H_Cont >= (X_START - 2) && H_Cont < (X_START + H_SYNC_ACT - 2) &&
		 		      V_Cont >= (Y_START) && V_Cont < (Y_START + V_SYNC_ACT));
//assign oVGA_SYNC  = 1'b0;
//assign oVGA_CLOCK = Clock;

// X and Y coordinates of pixel position
assign oCoord_X = H_Cont - X_START;
assign oCoord_Y = V_Cont - Y_START;

//	H_Sync Generator
always_ff @(posedge Clock) begin
	if(reset) begin
		H_Cont <= 10'd0;
		oVGA_H_SYNC	<= 1'b0;
	end	else begin
		//	H_Sync Counter		
		if (H_Cont == H_SYNC_TOTAL-1) H_Cont <= 11'd0;
		else H_Cont <= H_Cont + 11'd1;
		
//		if (H_Cont < H_SYNC_TOTAL-1) H_Cont <= H_Cont + 11'd1;
//		else H_Cont <= 11'd0;
		
		//	H_Sync Generator
		if (H_Cont < H_SYNC_CYC) oVGA_H_SYNC <= 1'b0;
		else oVGA_H_SYNC <= 1'b1;
	end
end

//	V_Sync Generator
always_ff @(posedge Clock) begin
	if(reset) begin
		V_Cont <= 11'd0;
		oVGA_V_SYNC	<= 1'b0;
	end	else begin
		//	When H_Sync Re-start
		if (H_Cont == 11'd0) begin
			//	V_Sync Counter
			if (V_Cont == V_SYNC_TOTAL-1) V_Cont <= 11'd0;
			else V_Cont <= V_Cont + 11'd1;
			
//			if (V_Cont < V_SYNC_TOTAL-1) V_Cont <= V_Cont + 11'd1;
//			else V_Cont <= 11'd0;
			
			//	V_Sync Generator
			if (V_Cont < V_SYNC_CYC) oVGA_V_SYNC <= 1'b0;
			else oVGA_V_SYNC <= 1'b1;
		end
	end
end

// buffer the RGB signals to synchronize them with V_SYNC and H_SYNC
// the RGB signals need also to be disabled during blanking

//	V_Sync Generator
always_ff @(posedge Clock) begin
	if(reset) begin
		oVGA_R <= 10'h000;
		oVGA_G <= 10'h000;
		oVGA_B <= 10'h000;
	end else begin
		oVGA_R <= (H_Cont >= X_START && H_Cont < X_START + H_SYNC_ACT &&
		 		   V_Cont >= Y_START && V_Cont < Y_START + V_SYNC_ACT)
				   ? iRed : 10'd0;
		oVGA_G <= (H_Cont >= X_START && H_Cont < X_START + H_SYNC_ACT &&
				   V_Cont >= Y_START && V_Cont < Y_START + V_SYNC_ACT)
				   ? iGreen : 10'd0;
		oVGA_B <= (H_Cont >= X_START && H_Cont < X_START + H_SYNC_ACT &&
				   V_Cont >= Y_START && V_Cont < Y_START + V_SYNC_ACT)
				   ? iBlue : 10'd0;
	end
end

endmodule
