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

FMC Carrier Board voltage should be set to 2.5 V and set MicroZed to boot from SD card.

Assumes SD Card for boot and storing pics/vids.

Requires separate download of Xilinx XAPP1017 from the Xilinx website as you must agree separately 
to the terms of use of the design license agreement for the application.

Once downloaded, add the serdes_1_to_10_idelay_ddr.v file to the project and modify line 419 to:
assign rx_data[10*i+j] = dataout[10*i+9-j] ; //EDITED TO GIVE REVERSE BIT ORDER

Open Vivado, cd to the directory containing these files and run "source HFRC.tcl" in the tcl command window.
After creating the project, generate the bitstream, export the hardware to the SDK and open the SDK.
In the SDK, create a FSBL with a standalone OS platform and new BSP, and an empty C project to import the TestSD.c file.
Create the boot image by adding the files (in order): zynq fsbl elf file, the hardware bit file, and the C code elf.
Put boot image onto an SD card and you are good to go.

See the user guide pdf for information on operating the camera assuming the appropriate hardware.
