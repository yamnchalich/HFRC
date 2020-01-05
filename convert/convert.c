#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <limits.h>
#include <errno.h>
#include <string.h>
#include <math.h>
#include <windows.h>
#include <errno.h>

#define TRUE 1
#define FALSE 0

//MAIN-----------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------
int main(int argc, char **argv) {

    FILE *fp, *pic_file;
    int pixel_1, pixel_2, pixel_3, pixel_4, pixel_5, pixel_6, pixel_7, pixel_8;
    int frame_count = 0;
    //int debug_counter = 0;
    int counter = 0, counter_max = 163839;//1310719;
    int arg_count = 1;
    int pgm = FALSE;

    time_t rawtime;
    char buffer [255];

    if (argc == 1) {
        printf("\nHOW TO USE:\n");
        printf("\nconvert file_type_flag resol_flag file_1 file_2...\n");
        printf("\nfile_type_flag:  0 for pgm (portable graymap format)\n");
        printf("\t\t 1 to keep bin file format\n");
        printf("\nresol_flag:      0 for full res 1280x1024\n"); 
        printf("\t\t 1 for 640x480\n");
        printf("\t\t 2 for 256x256\n");
        printf("\nfile_i: \tbin file to convert, multiple files are supported at once\n");
        printf("\nexample uses:   convert 0 0 mem_dump_1.bin mem_dump_2.bin\n");
        printf("\t\tconvert 0 1 mem_dump_1.bin\n");
        printf("\t\tconvert 1 2 mem_dump_1.bin mem_dump_2.bin mem_dump_3.bin\n");
        return 0;
    }

    if (atoi(argv[1]) == 0) {
        pgm = TRUE;
        arg_count++;
    } else if (atoi(argv[1]) == 1) arg_count++;

    if (atoi(argv[2]) == 1) {
        counter_max = 38399;
        arg_count++;
    } else if (atoi(argv[2]) == 2) {
        counter_max = 8191;
        arg_count++;
    } else if (atoi(argv[2]) == 0) {
        arg_count++;
    }

    if (arg_count == argc) {
        fprintf(stderr, "error: please supply at least one .bin file to convert\n");
        exit(EXIT_FAILURE);
    }

    char time_string[100];
    time (&rawtime);
    sprintf(time_string, "frames_%s", ctime(&rawtime));

    // convert space,: to _ in
    char *p = time_string;
    for (; *p; ++p)
    {
        if (*p == ' ') *p = '_';
        else if (*p == ':') *p = '_';
    }
    time_string[strlen(time_string)-1] = 0; 
    //printf("tstring: %s\n", time_string);
    
    /*
    #ifdef __linux__
       mkdir(time_string, 777); 
    #else
       _mkdir(time_string);
    #endif
    */

    char syscall[150];
    sprintf(syscall, "mkdir %s", time_string);
    system(syscall);

    //if (CreateDirectory(time_string, NULL) == 0) printf("fail: %d\n", GetLastError());
    //return 0;

    printf("working...\n");

    while (arg_count < argc) {
        if ((fp = fopen(argv[arg_count], "rb")) == NULL) {
            fprintf(stderr, "error: no such input file\n");
            exit(EXIT_FAILURE);
        }
        
        if (pgm == TRUE) sprintf(buffer, "./%s/frame_%d.pgm", time_string, frame_count);
        else sprintf(buffer, "./%s/frame_%d.bin", time_string, frame_count);

        //printf("buffer: %s\n", buffer);
        while ((pixel_1 = fgetc(fp)) != EOF) {
            if (counter == 0) {
                if ((pic_file = fopen(buffer, "wb")) == NULL) {
                    fprintf(stderr, "error: cannot create output file\n");
                    exit(EXIT_FAILURE);
                }
                if (pgm == TRUE) {
                    if (counter_max == 38399) {
                        //640x480
                        fprintf(pic_file, "P5 640 480 255 ");
                    } else if (counter_max == 8191) {
                        //256x256
                        fprintf(pic_file, "P5 256 256 255 ");
                    } else {
                        //1280x1024
                        fprintf(pic_file, "P5 1280 1024 255 ");
                    }
                }
            }
            pixel_2 = fgetc(fp);
            pixel_3 = fgetc(fp);
            pixel_4 = fgetc(fp);
            pixel_5 = fgetc(fp);
            pixel_6 = fgetc(fp);
            pixel_7 = fgetc(fp);
            pixel_8 = fgetc(fp);
            //fprintf(pic_file, "%c%c%c%c%c%c%c%c", pixel_8, pixel_7, pixel_6, pixel_5, pixel_4, pixel_3, pixel_2, pixel_1);
            fprintf(pic_file, "%c%c%c%c%c%c%c%c", pixel_1, pixel_2, pixel_3, pixel_4, pixel_5, pixel_6, pixel_7, pixel_8);
            //printf("%x%x%x%x%x%x%x%x\n", pixel_8, pixel_7, pixel_6, pixel_5, pixel_4, pixel_3, pixel_2, pixel_1);
            /*
            printf("1: %d\n", pixel_8);
            printf("2: %d\n", pixel_7);
            printf("3: %d\n", pixel_6);
            printf("4: %d\n", pixel_5);
            printf("5: %d\n", pixel_4);
            printf("6: %d\n", pixel_3);
            printf("7: %d\n", pixel_2);
            printf("8: %d\n", pixel_1);
            */
            //debug_counter++;
            //if (debug_counter == 30) exit(EXIT_FAILURE);
            if (counter < counter_max) counter++;
            else {
                fclose(pic_file);
                frame_count++;
                if (pgm == TRUE) sprintf(buffer, "./%s/frame_%d.pgm", time_string, frame_count);
                else sprintf(buffer, "./%s/frame_%d.bin", time_string, frame_count);
                //printf("frame %d finished\n", frame_count);
                counter = 0;
            }
        }
        if (pixel_1 == EOF && ferror(fp))
        {
            perror("error: EOF hit too early");
            exit(EXIT_FAILURE);
        } 
        fclose(fp);
        arg_count++;
    }

    printf("finished!\n");
    
    return 0;
}
