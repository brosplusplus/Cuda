#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <vector>
#include <ctime>
#include "readpng.cpp"

typedef float*  vectorr;

#define SIZE 16

#ifndef PINNED
#define PINNED 0
#endif

__global__ void applyKK(int N, int M, int P, vectorr entrada, vectorr filt, vectorr sortida) {
	/* N ample de la matriu
	 * M alçada de la matriu
	 * P mida filtre
	 * entrada matriu d'entrada
	 * sortida matriu de sortida
	 * filt matriu filtre
	 */
	int row = blockIdx.y * blockDim.y + threadIdx.y;
	int mod = (P-1)/2;
	int j, k, l;
	float acc;
	for (j = mod; j < M-mod; ++j)
	{
		acc = 0;
		for (k=0; k<P; k++) {
			//calculem l'index dintre del filtre utilitzant 
			//mod com a pivot
			int indexi = (row+(k-mod))*N+j-mod;
			for (l=0; l<P; l++) {
				float aux = entrada[indexi+l];
				float auxb = filt[k*P+l];
				acc = acc + aux * auxb;
			}
		}
		sortida[row*N+j] =  acc;
	}
}

vectorr img2bw(int N, int M, unsigned char** foto, int offset)
{
			//0.21 R + 0.72 G + 0.07 B
	int i, j;
	//~ int count=0;
	int afegit = offset*2;
	int size = (N+afegit) * (M+afegit);
	vectorr ret = (vectorr) malloc(size*sizeof(float));
	fprintf(stderr, "%d -> %lu\n", (N*M), (N*M*sizeof(float)));
	for (i=0; i<M + offset; i++) {
		unsigned char* r;
		if (i < offset)
			r = foto[(M-1)-i];
		else if (i >= M)
			r = foto[i-M];
		else
			r = foto[i];			
		for (j=0; j<N + offset; j++) {
			unsigned char* ptr = &(r[j*4]);
			float aux = float(0.21*ptr[0] + 0.72*ptr[1] + 0.07*ptr[2])/255.0;
			ret[i*M+j] = aux;
		}
	}
	//~ fprintf(stderr, "Run over i: %d, j: %d, : count: %d", i, j, count);
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


void print(int N, int M, float *C)
{
	int i, j;
	for (i=0; i<N; i++) {
		for (j=0; j<M; j++) {
			printf("%f ", C[i*M+j]);
		}
		printf("\n");
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
	fprintf(stderr, "\nCOUNT: %d\n", count);
	return ret;
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
	
	vectorr 	h_in, d_in;
	vectorr		h_out, d_out, h_filt, d_filt;
	
	float TiempoTotal, TiempoKernel;
	cudaEvent_t E0, E1, E2, E3;

	
	while ((c = getopt (argc, argv, "g:lsbnaHi:o:")) != -1)
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
	
	fprintf(stderr, "toread\n");
	begin = clock();
	read_png_file(image);
	end = clock();
	//~ double elapsed_read = (double(end-begin)/CLOCKS_PER_SEC);
	
	if (png_get_color_type(png_ptr, info_ptr) == PNG_COLOR_TYPE_RGB)
		abort_("[process_file] input file is PNG_COLOR_TYPE_RGB but must be PNG_COLOR_TYPE_RGBA ",
						"(lacks the alpha channel)");

	if (png_get_color_type(png_ptr, info_ptr) != PNG_COLOR_TYPE_RGBA)
		abort_("[process_file] color_type of input file must be PNG_COLOR_TYPE_RGBA (%d) (is %d)",
					 PNG_COLOR_TYPE_RGBA, png_get_color_type(png_ptr, info_ptr));
	
	h_filt = gaussFilt(gauss);
	int mod = (gauss-1)/2; //per ampliar la foto i evitar segfault.
	h_in = img2bw(width, height, row_pointers, mod);

	N = height;
	  // numero de Threads en cada dimension 
	nThreads = SIZE;

  // numero de Blocks en cada dimension 
	nBlocks = N/nThreads; 
	
	numBytes = N * N * sizeof(float);
	numBytesF = gauss*gauss * sizeof(float);
	
	dim3 dimGrid(nBlocks, nBlocks, 1);
	dim3 dimBlock(nThreads, nThreads, 1);
	
	cudaEventCreate(&E0);
	cudaEventCreate(&E1);
	cudaEventCreate(&E2);
	cudaEventCreate(&E3);
  	
	if (PINNED) {
	// Obtiene Memoria [pinned] en el host
		//~ cudaMallocHost((unsigned char**)&row_pointers, numBytes); 
		cudaMallocHost((float**)&h_out, numBytes); 
		cudaMallocHost((vectorr*)&h_filt, numBytesF);
	}
	else {
		// Obtener Memoria en el host
		//~ row_pointers = (unsigned char**) malloc(numBytes); 
		h_out = (vectorr) malloc(numBytes); 
		h_filt = (vectorr) malloc(numBytesF);
	}
  
	cudaEventRecord(E0, 0);
	cudaEventSynchronize(E0);


	// Obtener Memoria en el device
	//~ cudaMalloc((unsigned char **)&d_in, numBytes); 
	cudaMalloc((vectorr*)&d_in, numBytes); 
	cudaMalloc((vectorr*)&d_out, numBytes); 
	cudaMalloc((vectorr*)&d_filt, numBytesF); 

	// Copiar datos desde el host en el device 
	cudaMemcpy(d_in, h_in, numBytes, cudaMemcpyHostToDevice);
	cudaMemcpy(d_filt, h_filt, numBytesF, cudaMemcpyHostToDevice);
	cudaMemcpy(d_out, h_out, numBytes, cudaMemcpyHostToDevice);


	cudaEventRecord(E1, 0);
	cudaEventSynchronize(E1);

	fprintf(stderr, "Abans kernel\n");
	// Ejecutar el kernel 
	/***********************/
	/***********************/
	/***********************/
	/***********************/
	applyKK<<<dimGrid, dimBlock>>>(N, N, gauss, d_in, d_filt, d_out);
	/***********************/
	/***********************/
	/***********************/
	/***********************/
	cudaEventRecord(E2, 0);
	cudaEventSynchronize(E2);

	// Obtener el resultado desde el host 
	cudaMemcpy(h_out, d_out, numBytes, cudaMemcpyDeviceToHost); 

	// Liberar Memoria del device 
	cudaFree(d_in);
	cudaFree(d_filt);
	cudaFree(d_out);

	cudaEventRecord(E3, 0);
	cudaEventSynchronize(E3);

	cudaEventElapsedTime(&TiempoTotal,  E0, E3);
	cudaEventElapsedTime(&TiempoKernel, E1, E2);
	printf("\nKERNEL 00\n");
	printf("Dimensiones: %dx%d\n", N, N);
	printf("nThreads: %dx%d (%d)\n", nThreads, nThreads, nThreads * nThreads);
	printf("nBlocks: %dx%d (%d)\n", nBlocks, nBlocks, nBlocks*nBlocks);
	if (PINNED) printf("Usando Pinned Memory\n");
	else printf("NO usa Pinned Memory\n");
	printf("Tiempo Global: %4.6f milseg\n", TiempoTotal);
	printf("Tiempo Kernel: %4.6f milseg\n", TiempoKernel);
	float ops = (float) gauss*( float) gauss * (float) N * (float) N;
	printf("Rendimiento Global: %4.2f GFLOPS\n", (ops / (1000000.0 * TiempoTotal)));
	printf("Rendimiento Kernel: %4.2f GFLOPS\n", (ops / (1000000.0 * TiempoKernel)));
	cudaEventDestroy(E0); cudaEventDestroy(E1); cudaEventDestroy(E2); cudaEventDestroy(E3);

	//~ begin = clock();
	//~ vectorr m = img2bw(width, height, row_pointers);
	//~ end = clock();
	//~ double elapsed_bw = double(end - begin) / CLOCKS_PER_SEC;
	//~ fprintf(stderr, "B&W2 -- %f\n", elapsed_bw);
	//~ vectorr filt;
	//~ vectorr C;
	//~ InitM(3,3,filt);
	//~ gaussFilt(3, filt);
	//~ print(3,3,filt);
	//~ C = TestCM(width, height, 3, m, filt);
	//~ fprintf(stderr, "TEST\n");
	
	row_pointers = greyChar(width, height, h_out);
	fprintf(stderr, "GREYED\n");
	write_png_file(output);	
	
	return 0;
}    

