#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "readpng.cpp"

#define N 16
#define M 32
#define K 200

//~ __global__ void (volatile int *foo) {
//~ 
//~ }



int main(int argc, char** argv)
{
	int c;
	int gauss=0, laplace=0, sharpen=0, bumping=0, noise=0, histo=0;
	char *image = NULL;
	
	while ((c = getopt (argc, argv, "glsbnaHi:")) != -1)
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
			case 's':
				sharpen = 1;
				break;
			default:
				abort();
		}
	}
	
	read_png_file(image);
    process_file();
	write_png_file("salida.png");	
	
	return 0;
}    

