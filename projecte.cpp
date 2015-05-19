#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

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
	vector ret = (vector) malloc(M*N*sizeof(float));
	fprintf(stderr, "%d -> %lu\n", (N*M), (N*M*sizeof(float)));
	for (i=0; i<M; i++) {
		fprintf(stderr, "%d-fila\n", i);
		unsigned char* r = foto[i];
		for (j=0; j<N; j++) {
			fprintf(stderr, "\t%d-columna\n", j);
			unsigned char* ptr = &(r[j*4]);
			fprintf(stderr, "gotcha\n");
			float aux = float(0.21*ptr[0] + 0.72*ptr[1] + 0.07*ptr[2])/255.0;
			fprintf(stderr, "floated\n");
			ret[j*M+j] = aux;
			fprintf(stderr, "stored\n");
		}
	}
	print(N, M, ret);
	return ret;
}

void InitM(int N, int M, vector Mat) {
   int i;
   for (i=0; i<N*M; i++) 
     Mat[i] = rand() / (float) RAND_MAX;
}




int TestCM(int N, int M, int P, vector A, vector B, vector C) {
   int i, j, k,l;
   float tmp;
   float acc;
   int mod=(P-1)/2;
   // El test completo es muy costoso, por eso sólo probamos algunos casos
   // Para comprobar completamente el resultado hay que poner: i++ y j++
   for (i=1; i<N-1; i++)
     for (j=1; j<M-1; j++) {
      acc = 0.0;
      for (k=0; k<P; k++) 
        for (l=0; l<P; l++) {
          acc = acc + A[(i+(k-mod))*M+(j+(l-mod))] * B[k*P+l];
        }
      C[i+M+j]=acc;
     }
   return 1;
}

unsigned char** greyChar(int N, int M, vector m)
{
	unsigned char** ret;
	int i,j;
	for (i=0; i<M; i++) {
		for (j=0; j<N; j++) {
			unsigned char c = m[i*N+j]*255;
			ret[i][0] = c;
			ret[i][1] = c;
			ret[i][2] = c;
			ret[i][3] = c;
		}
	}
	return ret;
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
	vector filt;
	vector C;
	InitM(3,3,filt);
	TestCM(width, height, 3, m, filt, C);
	row_pointers = greyChar(width, height, C);
	write_png_file(output);	
	
	return 0;
}    

