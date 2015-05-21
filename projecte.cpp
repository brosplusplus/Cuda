#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

#include "readpng.cpp"

typedef float*  vector;

//~ __global__ void img2bw() {
//~ 
//~ }
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

vector img2bw(int N, int M, unsigned char** foto)
{
			//0.21 R + 0.72 G + 0.07 B
	int i, j;
	int count=0;
	vector ret = (vector) malloc(M*N*sizeof(float));
	fprintf(stderr, "%d -> %lu\n", (N*M), (N*M*sizeof(float)));
	for (i=0; i<M; i++) {
		unsigned char* r = foto[i];
		for (j=0; j<N; j++) {
			unsigned char* ptr = &(r[j*4]);
			float aux = float(0.21*ptr[0] + 0.72*ptr[1] + 0.07*ptr[2])/255.0;
			ret[i*N+j] = aux;
			++count;
		}
	}
	fprintf(stderr, "Run over i: %d, j: %d, : count: %d", i, j, count);
	return ret;
}

void InitM(int N, int M, vector Mat) {
   int i;
   srand(time(NULL));
   for (i=0; i<N*M; i++) 
     Mat[i] = rand() / (float) RAND_MAX;
}




vector TestCM(int N, int M, int P, vector A, vector B) {
	int i, j, k,l;
	float tmp;
	float acc;
	int count;
	int mod=(P-1)/2;
	vector C = (vector) malloc(N*M*sizeof(float));
  fprintf(stderr, "M=%d, N=%d\n", M, N); 
	for (i=1; i<M-1; i++) {
		for (j=1; j<N-1; j++) {
			acc = 0.0;
			//~ fprintf(stderr, "i: %d, j: %d\n", i, j);
			for (k=0; k<P; k++) {
				for (l=0; l<P; l++) {
					float aux = A[(i+(k-mod))*N+(j+(l-mod))];
					float auxb = B[k*P+l];
					acc = acc + aux * auxb;
					count++;
				}
			}
			if (acc > 1.0) 
				acc = 1.0;
			C[i*M+j]=acc;
		}
	}
	fprintf(stderr, "count: %d", count);
  return C;
}

unsigned char** greyChar(int N, int M, vector m)
{
	unsigned char** ret = (unsigned char**) malloc(M*sizeof(unsigned char*));
	int i,j;
	for (i=0; i<M; i++) {
		unsigned char* row = (unsigned char*) malloc(4*N*sizeof(unsigned char));
		for (j=0; j<N; j++) {
			unsigned char c = m[i*N+j]*255;
			int k = j*4;
			row[k+0] = c;
			row[k+1] = c;
			row[k+2] = c;
			row[k+3] = (unsigned char) 255;
		}
		ret[i] = row;
	}
	return ret;
}

void gaussFilt(int n, vector &ret){
	printf("GAUSS\n");
	ret = (vector)malloc(n*n*sizeof(float));
	int i,j;
	for (i = 0; i < n*n; i++) {
		ret[i] = 1/9.;
	}
	ret[4] = 1/9.;
}

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
	fprintf(stderr, "height:%d, width: %d", height, width);
	if (image == NULL) {
		fprintf(stderr, "ERROR: Necesito una imagen\n");
		return -1;
	}
	if (output == NULL) {
		fprintf(stderr, "WARN: Tomando salida por defecto : salida.png\n");
		output = "salida.png";
	}
	fprintf(stderr, "toread\n");
	read_png_file(image);
	fprintf(stderr, "readed\n");
	if (png_get_color_type(png_ptr, info_ptr) == PNG_COLOR_TYPE_RGB)
		abort_("[process_file] input file is PNG_COLOR_TYPE_RGB but must be PNG_COLOR_TYPE_RGBA "
					 "(lacks the alpha channel)");

	if (png_get_color_type(png_ptr, info_ptr) != PNG_COLOR_TYPE_RGBA)
		abort_("[process_file] color_type of input file must be PNG_COLOR_TYPE_RGBA (%d) (is %d)",
					 PNG_COLOR_TYPE_RGBA, png_get_color_type(png_ptr, info_ptr));

	vector m = img2bw(width, height, row_pointers);
	fprintf(stderr, "B&W2\n");
	vector filt;
	vector C;
	//~ InitM(3,3,filt);
	gaussFilt(3, filt);
	print(3,3,filt);
	C = TestCM(width, height, 3, m, filt);
	fprintf(stderr, "TEST\n");
	fprintf(stderr, "PRINTED\n");
	row_pointers = greyChar(width, height, C);
	fprintf(stderr, "GREYED\n");
	write_png_file(output);	
	
	return 0;
}    

