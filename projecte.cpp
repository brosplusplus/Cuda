#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "readpng.cpp"

#define N 16
#define M 32

//~ __global__ void (volatile int *foo) {
//~ 
//~ }



int main(int argc, char** argv)
{
	int c;
	int gauss=0, laplace=0, sharpen=0, bumping=0, noise=0, histo=0;
	char *image = NULL;
        char *output = NULL;
	
	//~ unsigned int N;
	//~ unsigned int numBytes;
	//~ unsigned int nBlocks, nThreads;
//~ 
	//~ float TiempoTotal, TiempoKernel;
	//~ cudaEvent_t E0, E1, E2, E3;
//~ 
	//~ float *h_A, *h_B, *h_C;
	//~ float *d_A, *d_B, *d_C;
	
	while ((c = getopt (argc, argv, "glsbnaHi:o:")) != -1)
	{
		switch (c)
		{
			case 'a':
				gauss=laplace=sharpen=bumping=noise=histo=1;
				break;
			case 'b':
				bumping = 1;
				break;
			case 'g':
				gauss=1;
				break;
			case 'H':
				histo = 1;
				break;
			case 'i':
				image = optarg;
				break;
			case 'l':
				laplace = 1;
				break;
			case 'n':
				noise = 1;
				break;
                        case 'o':
                                output = optarg;
                                break;
			case 's':
				sharpen = 1;
				break;
			default:
				abort();
		}
	}
	if (image == NULL) {
                fprintf(stderr, "ERROR: Necesito una imagen\n");
                return -1;
        }
        if (output == NULL) {
                fprintf(stderr, "WARN: Tomando salida por defecto : salida.png\n");
                output = "salida.png";
        }
	read_png_file(image);
    process_file();
	write_png_file(output);	
	
	return 0;
}    

