#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <vector>
#include <ctime>
#include "readpng.cpp"

typedef float*  vectorr;


vectorr img2bw(int N, int M, unsigned char** foto)
{
			//0.21 R + 0.72 G + 0.07 B
	int i, j;
	//~ int count=0;
	int size = N*M;
	vectorr ret = (vectorr) malloc(size*sizeof(float));
	//~ fprintf(stderr, "%d -> %lu\n", (N*M), (N*M*sizeof(float)));
	for (i=0; i<M; i++) {
		unsigned char* r = foto[i];			
		for (j=0; j<N; j++) {
			unsigned char* ptr = &(r[j*4]);
			float aux = float(0.21*ptr[0] + 0.72*ptr[1] + 0.07*ptr[2])/255.0;
			ret[i*M+j] = aux;
		}
	}
	//~ fprintf(stderr, "Run over i: %d, j: %d, : count: %d", i, j, count);
	return ret;
}

void TestCM(int N, int M, int P, vectorr A, vectorr B, vectorr C) {
	int i, j, k,l;
	float tmp;
	float acc;
	int count;
	int mod=(P-1)/2;
	C = (vectorr) malloc(N*M*sizeof(float));
	for (i=1; i<N-(mod-1); i++) {
		for (j=1; j<M-(mod-1); j++) {
			acc = 0.0;
			for (k=0; k<P; k++) {
				for (l=0; l<P; l++) {
					float aux = A[(i+(k-mod))*M+(j+(l-mod))];
					float auxb = B[k*P+l];
					acc = acc + aux * auxb;
					count++;
				}
			}
			if (acc >= 1.0) {
				//fprintf(stderr, "i: %d, j:%d, PACO: %f", i, j, acc);
				acc = 1.0;
			}
			C[i*M+j]=acc;
		}
	}
}

unsigned char** greyChar(int N, int M, vectorr m)
{
	unsigned char** ret = (unsigned char**) malloc(M*sizeof(unsigned char*));
	//~ std::vector<bool> v(N*M*sizeof(float));
	int i,j;
	int count = 0;
	for (i=0; i<M; i++) {
		unsigned char* row = (unsigned char*) malloc(4*N*sizeof(unsigned char));
		for (j=0; j<N; j++) {
			unsigned char c = m[i*M+j]*255;
			//~ if (v[i*N+j])
				//~ count++;
			//~ else
				//~ v[i*N+j] = true;
			int k = j*4;
			row[k+0] = c;
			row[k+1] = c;
			row[k+2] = c;
			row[k+3] = (unsigned char) 255;
		}
		ret[i] = row;
	}
	//~ fprintf(stderr, "\nCOUNT: %d\n", count);
	return ret;
}

vectorr gaussFilt(int N)
{
	vectorr ret = (vectorr) malloc(N*N*sizeof(float));
	float value = 1.0/(N*N);
	for (int i = 0; i < N*N; i++)
		ret[i] = value;
	return ret;
}

vectorr laplaceFilt()
{
	
	vectorr ret = (vectorr) malloc(3*3*sizeof(float));
	ret[0] = 0;
	ret[1] = -1;
	ret[2] = 0;
	ret[3] = -1;
	ret[4] = 4;
	ret[5] = -1;
	ret[6] = 0;
	ret[7] = -1;
	ret[8] = 0;
	return ret;
}



void printPerf(float TiempoTotal, float TiempoAplic, float ops)
{
	printf("Filter application CPU");
	printf("Tiempo Global: %4.6f milseg\n", TiempoTotal);
	printf("Tiempo Aplicar Filtro: %4.6f milseg\n", TiempoAplic);
	printf("Rendimiento Global: %4.2f GFLOPS\n", (ops / (1000000.0 * TiempoTotal)));
	printf("Rendimiento Kernel: %4.2f GFLOPS\n", (ops / (1000000.0 * TiempoAplic)));
}

int main(int argc, char** argv)
{
	int c;
	int gauss=0, laplace=0, sharpen=0, bumping=0, noise=0, histo=0;
	char *image = NULL;
	char *output = NULL;
	clock_t begin, end;
	
	unsigned int N;
	unsigned int numBytes, numBytesF;
	unsigned int nBlocks, nThreads;
	
	vectorr 	h_in;
	vectorr		h_out_gauss, h_out_laplace;
	vectorr		h_filt_gauss,
				h_filt_lapla;
	
	float TiempoTotal, TiempoAplic,
			elapsed_read,
			elapsed_write;

	
	while ((c = getopt (argc, argv, "g:lsbnaHi:o:")) != -1)
	{
		switch (c)
		{
			case 'a':
				gauss=3;
				laplace=sharpen=bumping=noise=histo=1;
				break;
			case 'b':
				bumping = 1;
				break;
			case 'g':
				gauss=atoi(optarg);
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
	
	//~ fprintf(stderr, "toread\n");
	begin = clock();
	read_png_file(image);
	end = clock();
	elapsed_read = (float(end-begin)/CLOCKS_PER_SEC);
	if (png_get_color_type(png_ptr, info_ptr) == PNG_COLOR_TYPE_RGB)
		abort_("[process_file] input file is PNG_COLOR_TYPE_RGB but must be PNG_COLOR_TYPE_RGBA ",
						"(lacks the alpha channel)");

	if (png_get_color_type(png_ptr, info_ptr) != PNG_COLOR_TYPE_RGBA)
		abort_("[process_file] color_type of input file must be PNG_COLOR_TYPE_RGBA (%d) (is %d)",
					 PNG_COLOR_TYPE_RGBA, png_get_color_type(png_ptr, info_ptr));
	begin = clock();
	h_in = img2bw(width, height, row_pointers);
	end = clock();
	elapsed_read += (float(end-begin)/CLOCKS_PER_SEC);
	
	N = height;
	numBytes = N * N * sizeof(float);
	numBytesF = gauss*gauss * sizeof(float);		
	
	if (gauss != 0)
	{
		int mod = (gauss-1)/2;
		/***********************/
		/***********************/
		/***********************/
		/***********************/
		begin = clock();
		h_out_gauss = (vectorr) malloc(numBytes); 
		h_filt_gauss = gaussFilt(gauss);
		TestCM(N, N, gauss, h_in, h_filt_gauss, h_out_gauss);
		end = clock();
		TiempoAplic = (float(end-begin)/CLOCKS_PER_SEC);
		/***********************/
		/***********************/
		/***********************/
		/***********************/

		begin = clock();
		row_pointers = greyChar(width, height, h_out_gauss);
		write_png_file(output);	
		end = clock();
		elapsed_write = (float(end-begin)/CLOCKS_PER_SEC);

		float ops = (N-mod)*(N-mod) * (gauss*gauss);
		printPerf(elapsed_read+elapsed_write+TiempoAplic, TiempoAplic, ops);
	}
	if (laplace)
	{
		int mod = (gauss-1)/2;
		/***********************/
		/***********************/
		/***********************/
		/***********************/
		begin = clock();
		h_out_laplace = (vectorr) malloc(numBytes); 
		h_filt_lapla = laplaceFilt();
		TestCM(N, N, gauss, h_in, h_filt_lapla, h_out_laplace);
		end = clock();
		TiempoAplic = (float(end-begin)/CLOCKS_PER_SEC);
		/***********************/
		/***********************/
		/***********************/
		/***********************/

		begin = clock();
		row_pointers = greyChar(width, height, h_out_laplace);
		write_png_file(output);	
		end = clock();
		elapsed_write = (float(end-begin)/CLOCKS_PER_SEC);

		float ops = (N-mod)*(N-mod) * (3*3);
		printPerf(elapsed_read+elapsed_write+TiempoAplic, TiempoAplic, ops);
	}	
	return 0;
}  
