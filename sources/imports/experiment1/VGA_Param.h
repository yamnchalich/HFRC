/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/
/*
//  640 X 480 @ 59.94Hz with a 25.175MHz pixel clock (in our implementation we use a 25MHz clock)
//	Horizontal Parameters
parameter	H_SYNC_CYC	 = 10'd96;
parameter	H_SYNC_BACK	 = 10'd48;
parameter	H_SYNC_ACT	 = 10'd640;
parameter	H_SYNC_TOTAL = 10'd800;
// parameter	H_SYNC_FRONT = 10'd16; // H_SYNC_TOTAL - H_SYNC_ACT - H_SYNC_CYC - H_SYNC_BACK;
//	Vertical Parameters
parameter	V_SYNC_CYC	 = 10'd2;
parameter	V_SYNC_BACK	 = 10'd31;
parameter	V_SYNC_ACT	 = 10'd480;
parameter	V_SYNC_TOTAL = 10'd524;
// parameter	V_SYNC_FRONT = 10'd11; // V_SYNC_TOTAL - V_SYNC_ACT - V_SYNC_CYC - V_SYNC_BACK;
*/

//  1280 X 1024 @ 60Hz with a 108MHz pixel clock
//	Horizontal Parameters
parameter	H_SYNC_CYC	 = 11'd112;
parameter	H_SYNC_BACK	 = 11'd248;
parameter	H_SYNC_ACT	 = 11'd1280;
parameter	H_SYNC_TOTAL = 11'd1688;
// parameter	H_SYNC_FRONT = 10'd48; // H_SYNC_TOTAL - H_SYNC_ACT - H_SYNC_CYC - H_SYNC_BACK;
//	Vertical Parameters
parameter	V_SYNC_CYC	 = 11'd3;
parameter	V_SYNC_BACK	 = 11'd38;
parameter	V_SYNC_ACT	 = 11'd1024;
parameter	V_SYNC_TOTAL = 11'd1066;
// parameter	V_SYNC_FRONT = 10'd1; // V_SYNC_TOTAL - V_SYNC_ACT - V_SYNC_CYC - V_SYNC_BACK;

/*
// 800 X 600 @ 72Hz with a 50.000MHz pixel clock
//	Horizontal Parameters
parameter	H_SYNC_CYC	 = 10'd120;
parameter	H_SYNC_BACK	 = 10'd64;
parameter	H_SYNC_ACT	 = 10'd800;
parameter	H_SYNC_TOTAL = 10'd1023;
// parameter	H_SYNC_FRONT = 10'd39; // H_SYNC_TOTAL - H_SYNC_ACT - H_SYNC_CYC - H_SYNC_BACK;
//	Vertical Parameters
parameter	V_SYNC_CYC	 = 10'd6;
parameter	V_SYNC_BACK	 = 10'd23;
parameter	V_SYNC_ACT	 = 10'd600;
parameter	V_SYNC_TOTAL = 10'd678;
// parameter	V_SYNC_FRONT = 10'd49; // V_SYNC_TOTAL - V_SYNC_ACT - V_SYNC_CYC - V_SYNC_BACK;
*/

//	Start Offset
parameter	X_START = H_SYNC_CYC + H_SYNC_BACK;
parameter	Y_START = V_SYNC_CYC + V_SYNC_BACK;
