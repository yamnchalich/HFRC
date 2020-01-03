# HFRC
High Frame Rate Camera Project developed using the free Vivado WebPACK version 2017.4.1. 
Compatible with a MicroZed 7020 SoC + FMC Carrier Board + PMOD attachments (VGA, switches, and pushbuttons) + custom daughter PCB containing the PYTHON 1300 monochrome image sensor.

Can operate in the following configurations:

| Resolution        | Framerates    | Record Time (s) (8-bit pixels, ~1 GB storage) |
| -------------     | ------------- | ----------------------------- |
| 1280x1024 (SXGA)  | 211 (MAX)     | 3.86                          |
|                   | 100           | 8.14                          |
|                   | 60            | 13.57                         |
|                   | 30            | 27.13                         |
| 640x480 (VGA)     | 817 (MAX)     | 4.25                          |
|                   | 400           | 8.69                          |
| 256x256           | 2329 (MAX)    | 6.99                          |
|                   | 1000          | 16.29                         |  

FMC Carrier Board voltage should be set to 2.5 V.

Assumes SD Card for boot and storing pics/vids.

Requires separate download of Xilinx XAPP1017 from the Xilinx website as you must agree separately 
to the terms of use of the design license agreement for the application.

Once downloaded, add the serdes_1_to_10_idelay_ddr.v file to the project and modify line 419 to:
assign rx_data[10*i+j] = dataout[10*i+9-j] ; //EDITED TO GIVE REVERSE BIT ORDER
