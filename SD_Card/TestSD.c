/******************************************************************************
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
******************************************************************************
*
* @file xilffs_polled_example.c
*
*
* @note This example uses file system with SD to write to and read from
* an SD card using ADMA2 in polled mode.
* To test this example File System should not be in Read Only mode.
* To test this example USE_MKFS option should be true.
*
* This example was tested using SD2.0 card and eMMC (using eMMC to SD adaptor).
*
* To test with different logical drives, drive number should be mentioned in
* both FileName and Path variables. By default, it will take drive 0 if drive
* number is not mentioned in the FileName variable.
* For example, to test logical drive 1
* FileName =  "1:/<file_name>" and Path = "1:/"
* Similarly to test logical drive N, FileName = "N:/<file_name>" and
* Path = "N:/"
******************************************************************************/

// Edited by: Yamn Chalich //

/***************************** Include Files *********************************/

#include "xparameters.h"	/* SDK generated parameters */
#include "xsdps.h"		/* SD device driver */
#include "xil_printf.h"
#include "ff.h"
//#include "xbram.h"
#include "xil_cache.h"
#include "xplatform_info.h"
#include "xil_io.h"

/************************** Constant Definitions *****************************/
//#define BRAM_DEVICE_ID		XPAR_AXI_BRAM_CTRL_0_DEVICE_ID
/**************************** Type Definitions *******************************/
/***************** Macros (Inline Functions) Definitions *********************/
/************************** Function Prototypes ******************************/

int FfsSdPolledExample(void);
int STORE_TO_SD_CARD(int flag, int num);
void make_filename(char *name_array1, char *name_array2, char *name_array3, int count1, int count2);
int write(char *filename, u32 header_size, char *hp, u32 file_size, u32 *file_start_addr);
//int write_bin(char *filename, u32 file_size, u32 *file_start_addr);
char *increment_num_in_name(char *given_p);

/************************** Variable Definitions *****************************/
static FIL fil;		/* File object */
//static DIR dir;		/* Directory object */
static FATFS fatfs;
/*
 * To test logical drive 0, FileName should be "0:/<File name>" or
 * "<file_name>". For logical drive 1, FileName should be "1:/<file_name>"
 */
static char FileName[32] = "";
static char pic_prefix[6] = "/p_"; //pp
static char vid_prefix[8] = "/vid"; //vp
static char folder_prefix[5] = "VID_"; //fp
static char itoa_buffer[10] = "";
static char pgm[5] = ".pgm";
static char bin[5] = ".bin";
static char header_max[] = "P5 1280 1024 255 ";
static char header_640[] = "P5 640 480 255 ";
static char header_256[] = "P5 256 256 255 ";

//static char *SD_File;
u32 Platform;

//u8 DestinationAddress[10*1024*1024] __attribute__ ((aligned(32)));
//u8 SourceAddress[10*1024*1024] __attribute__ ((aligned(32)));

#define TEST 7
#define PIC 0
#define VID 1


u32 *DDR_BASE_ADDR = (u32 *)(XPAR_PS7_DDR_0_S_AXI_BASEADDR+1310720);//+22282240); //+17 frames to store app in RAM
u32 *DDR_PIC_ADDR = (u32 *)(XPAR_PS7_DDR_0_S_AXI_BASEADDR+2621440+1310720);//+22282240); //+ 2 frames (vga frames)
u32 *DDR_VID_ADDR = (u32 *)(XPAR_PS7_DDR_0_S_AXI_BASEADDR+3932160+1310720);//+22282240); //+ 3 frames (vga frames + pic)

u32 *PS_TO_PL = (u32 *)XPAR_PS_PL_COMM_0_S00_AXI_BASEADDR;
u32 *PL_TO_PS = (u32 *)(XPAR_PS_PL_COMM_0_S00_AXI_BASEADDR+4);
u32 *PL_TO_PS_1 = (u32 *)(XPAR_PS_PL_COMM_0_S00_AXI_BASEADDR+8);
u32 *PL_TO_PS_2 = (u32 *)(XPAR_PS_PL_COMM_0_S00_AXI_BASEADDR+12);

//u32 MASK_PIC = 0x00000001;
//u32 MASK_VID = 0x00000002;

int main(void)
{
	int Status = 0;
	int pic_num = 1;
	int folder_num = 1;
	FRESULT Res;

	xil_printf("SD Card Storage Start\r\n");
	//xil_printf("DDR_BASE_ADDR: %d \r\n", DDR_BASE_ADDR);
	//xil_printf("DDR_PIC_ADDR: %d \r\n", DDR_PIC_ADDR);

	/*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	Platform = XGetPlatform_Info();

	/* Register volume work area, initialize device	 */
	Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK) {
		xil_printf("SD f_mount failed \r\n");
		return XST_FAILURE;
	}

	while (1) {
		if (*PL_TO_PS == 0x00000001 || *PL_TO_PS == 0x00000005 || *PL_TO_PS == 0x00000009) {
			//start PIC storage
			//acknowledge that PIC storage has commenced
			xil_printf("PL_TO_PS: 0x%08x \r\n", *PL_TO_PS);
			xil_printf("PL_TO_PS_1: 0x%08x \r\n", *PL_TO_PS_1);
			*(PS_TO_PL) = 0x00000001;
			Status = STORE_TO_SD_CARD(PIC, pic_num);
			pic_num++;
			if (Status != XST_SUCCESS) {
				xil_printf("Failed to write PIC to SD Card\r\n");
				return XST_FAILURE;
			} else {
				//indicate PIC storage is finished
				*(PS_TO_PL) = 0x00000000;
				xil_printf("Finished writing PIC to SD Card\r\n");
			}
			//print fps
			xil_printf("fps: %d, clock cycles per frame at 72 MHz clock: %d \r\n", 72000000 / *PL_TO_PS_1, *PL_TO_PS_1);
		} else if (*PL_TO_PS == 0x00000002 || *PL_TO_PS == 0x00000006 || *PL_TO_PS == 0x0000000A) {
			//start VID storage
			//acknowledge that VID storage has commenced
			xil_printf("PL_TO_PS: 0x%08x \r\n", *PL_TO_PS);
			xil_printf("PL_TO_PS_1: 0x%08x \r\n", *PL_TO_PS_1);
			*(PS_TO_PL) = 0x00000002;
			xil_printf("Started storing vid \r\n");
			Status = STORE_TO_SD_CARD(VID, folder_num);
			folder_num++;
			if (Status != XST_SUCCESS) {
				xil_printf("Failed to write VID to SD Card\r\n");
				return XST_FAILURE;
			} else {
				//indicate VID storage is finished
				*(PS_TO_PL) = 0x00000000;
				xil_printf("Finished writing VID to SD Card\r\n");
			}
		}
	}
	return XST_SUCCESS;
}

int STORE_TO_SD_CARD(int flag, int num) {

	int Status;
	FRESULT Res;
	//UINT NumBytesRead;
	UINT NumBytesWritten;
	//u32 BuffCnt;
	u32 header_filesize_0 = 17;
	//u32 header_filesize_1 = 15;
	u32 frame_max_filesize = 1310720;
	//u32 frame_640_filesize = 307200;
	//u32 frame_256_filesize = 65536;
	u32 bin_size = 1066926080;
	//u32 storage_count_reset = 133365759;
	//int num_frames_max = 778;

	u32 store_size_1;
	u32 store_size_2;
	u32 *vid_start_addr_1;
	u32 *vid_start_addr_2 = DDR_VID_ADDR;

	char *ppp = pic_prefix;
	char *vpp = vid_prefix;
	char *fpp = folder_prefix;
	char *pgmp = pgm;
	char *binp = bin;
	char *SD_File = FileName;
	char *empty = "";
	//char *num_p;
	char *header = header_max;
	//u32 *addr_p;
	//int addr_p_incr = 327680;

	//int vid_count = 1;

	//need to change header, header_size, frame_filesize, num_frames, addr_p increment
	if (*PL_TO_PS > 3) {
		header_filesize_0 = 15;
		if (*PL_TO_PS > 7) {
			//256 RES
			frame_max_filesize = 65536;
			header = header_256;
			bin_size = 1067450368;
			xil_printf("res_256 \r\n");
		} else {
			//VGA RES
			frame_max_filesize = 307200;
			header = header_640;
			bin_size = 1067212800;
			xil_printf("res_vga \r\n");
		}
	}

	if (flag == PIC) {
		//store PIC
		//addr_p = DDR_PIC_ADDR;
		make_filename(empty, ppp, pgmp, 0, num);
		Status = write(SD_File, header_filesize_0, header, frame_max_filesize, DDR_PIC_ADDR);
		if (Status != XST_SUCCESS) {
			xil_printf("Write of pic_frame %d failed \r\n", num);
			return XST_FAILURE;
		}
	} else {
		//if (1), store VID
		//make directory/folder and go into it
		make_filename(empty, fpp, empty, 0, num);
		Res = f_mkdir(SD_File);
		if (Res != XST_SUCCESS) {
			xil_printf("Creation of directory %d failed \r\n" ,num);
			return XST_FAILURE;
		}
		/*
		Res = f_opendir(&dir, SD_File);
		if (Res != XST_SUCCESS) {
			xil_printf("Opening of directory %d failed \r\n" ,num);
			return XST_FAILURE;
		}
		*/

		vid_start_addr_1 = ((*PL_TO_PS_2 + 1) << 1) + DDR_VID_ADDR;
		store_size_1 = bin_size - ((*PL_TO_PS_2 + 1) << 3);

		xil_printf("write_counter: %d, +1: %d, start_1: 0x%08x, store_1: %d \r\n", *PL_TO_PS_2, (*PL_TO_PS_2 + 1), vid_start_addr_1, store_size_1);

		//vid_start_addr_2 = ((*PL_TO_PS_2 + 1) << 1) + DDR_VID_ADDR;
		store_size_2 = bin_size - store_size_1;

		//create VID.BIN file ---------------------------------------------------------------------------------------
		make_filename(fpp, vpp, binp, num, 0);
		Res = f_open(&fil, SD_File, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);

		/* Pointer to beginning of file .	 */
		Res = f_lseek(&fil, 0);

		/* Write only second part (full) if no first part. */
		if (store_size_1 != 0) Res = f_write(&fil, (const void*)vid_start_addr_1, store_size_1, &NumBytesWritten);

		Res = f_write(&fil, (const void*)vid_start_addr_2, store_size_2, &NumBytesWritten);

		Res = f_close(&fil);
	}
	return XST_SUCCESS;
}

void make_filename(char *name_array1, char *name_array2, char *name_array3, int count1, int count2) {
	//edit static FileName
	//aka concat + itoa
	char *itoap;
	char *p = FileName;
	while (*name_array1 != 0) {
	   *p = *name_array1;
	   p++;
	   name_array1++;
	}
	if (count1 != 0) {
		itoap = itoa_buffer + sizeof itoa_buffer - 1; // pointer to end of buffer
		*itoap-- = 0; // 0 - end of string
		while ( count1 > 0 )
		{
		  *itoap-- = (char)( ( count1 % 10 ) + '0' );
		  count1 /= 10;
		}
		itoap++;
		while (*itoap != 0) {
		   *p = *itoap;
		   p++;
		   itoap++;
		}
	}

	//xil_printf("itoap: %s \r\n", itoap);
	while (*name_array2 != 0) {
	   *p = *name_array2;
	   p++;
	   name_array2++;
	}
	if (count2 != 0) {
		itoap = itoa_buffer + sizeof itoa_buffer - 1; // pointer to end of buffer
		*itoap-- = 0; // 0 - end of string
		while ( count2 > 0 )
		{
		  *itoap-- = (char)( ( count2 % 10 ) + '0' );
		  count2 /= 10;
		}
		itoap++;
		while (*itoap != 0) {
		   *p = *itoap;
		   p++;
		   itoap++;
		}
	}
	while (*name_array3 != 0) {
	   *p = *name_array3;
	   p++;
	   name_array3++;
	}
	*p = 0;
}

char *increment_num_in_name(char *given_p) {
	//p points to last num in file naming
	char *p = given_p;
	char *return_p = given_p;
	int counter = 0;

	while (*p == '9') {
		counter++;
		*p = '0';
		p--;
	}
	if (*p == '_') {
		//must shift, reattach .pgm
		p++;
		*p = '1';
		p = p + counter;
		*p = '0';
		return_p = p;
		p++;
		*p = '.';
		p++;
		*p = 'p';
		p++;
		*p = 'g';
		p++;
		*p = 'm';
		p++;
		*p = 0; //NUL
	} else {
		//increment current number, done
		*p = *p + 1;
	}
	return return_p;
}

int write(char *filename, u32 header_size, char *hp, u32 file_size, u32 *file_start_addr) {
	//open, write to, and close file
	//FRESULT Res;
	UINT NumBytesWritten;
	f_open(&fil, filename, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);
	/*
	if (Res) {
		xil_printf("SD f_open failed, res: %d \r\n", Res);
		return XST_FAILURE;
	}
	*/
	/* Pointer to beginning of file .	 */
	f_lseek(&fil, 0);
	/*
	if (Res) {
		xil_printf("SD f_lseek failed \r\n");
		return XST_FAILURE;
	}
	*/
	/* Write header data to file.	 */
	f_write(&fil, (const void*)hp, header_size,
			&NumBytesWritten);
	/*
	if (Res) {
		xil_printf("SD f_write failed \r\n");
		return XST_FAILURE;
	}
	if (NumBytesWritten != header_size) {
		xil_printf("NumBytesWritten not full header \r\n");
		return XST_FAILURE;
	}
	*/
	/* Write frame data to file.	 */
	f_write(&fil, (const void*)file_start_addr, file_size,
			&NumBytesWritten);
	/*
	if (Res) {
		xil_printf("SD f_write failed \r\n");
		return XST_FAILURE;
	}
	if (NumBytesWritten != file_size) {
		xil_printf("NumBytesWritten not full frame \r\n");
		return XST_FAILURE;
	}
	*/
	f_close(&fil);
	/*
	if (Res) {
		return XST_FAILURE;
	}
	*/
	return XST_SUCCESS;
}

/*
int write_bin(char *filename, u32 file_size, u32 *file_start_addr) {
	//open, write to, and close file
	FRESULT Res;
	UINT NumBytesWritten;
	Res = f_open(&fil, filename, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);

	// Pointer to beginning of file .
	Res = f_lseek(&fil, 0);

	// Write bin data to file.
	Res = f_write(&fil, (const void*)file_start_addr, file_size,
			&NumBytesWritten);

	Res = f_close(&fil);

	return XST_SUCCESS;

}
*/
