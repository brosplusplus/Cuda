#include <stdio.h>
#include <stdlib.h>
#include "readpng.cpp"

#define SIZE 16

#ifndef PINNED
#define PINNED 0
#endif


//Tamaño de la matrix filtro: 3x3
#define CONVSIZE 3

// Matriz por Matriz
// C(NxM) <- A(NxP) * B (PxM)

//~ __global__ void Kernel11(int N, int M, int P, float *A, float *B, float *C) {
//~ 
  //~ __shared__ float sA[SIZE][SIZE];
  //~ __shared__ float sB[SIZE][SIZE];
//~ 
  //~ int bx = blockIdx.x;  int by = blockIdx.y;
  //~ int tx = threadIdx.x; int ty = threadIdx.y;
  //~ int row = by * SIZE + ty;
  //~ int col = bx * SIZE + tx;
  //~ int m, k, iter;
  //~ 
//~ }



void InitM(int N, int M, float *Mat);
int TestCM(int N, int M, int P, float *A, float *B, float *C);
void print(int N, int M, float *C);

// Invocacion:
// ./ejecutable TAM test
// TAM es el la dimension de las matrices
// test == 'Y', comprueba que el resultado sea correcto
// test == 'N', NO comprueba que el resultado (Util para tomar tiempos)
// Por defecto, N = 2048, test == 'N'

int main(int argc, char** argv)
{
  unsigned int N, cN = CONVSIZE;
  unsigned int numBytes, convBytes;
  unsigned int nBlocks, nThreads;
 
  float TiempoTotal, TiempoKernel;
  //~ cudaEvent_t E0, E1, E2, E3;

  float *h_A, *h_B, *h_C;
  float *d_A, *d_B, *d_C;

  char test;

  // Dimension de las matrices NxN y comprobacion resultado
  if (argc == 1)      { test = 'N'; N = 2048; }
  else if (argc == 2) { test = 'N'; N = atoi(argv[1]); }
  else if (argc == 3) { test = 'Y'; N = atoi(argv[1]); cN = atoi(argv[2]); }
  else { printf("Usage: ./exe TAM test\n"); exit(0); }

  // numero de Threads en cada dimension 
  nThreads = SIZE;

  // numero de Blocks en cada dimension 
  nBlocks = (N+nThreads-1)/nThreads; 
  
  numBytes = N * N * sizeof(float);
  convBytes = cN * cN * sizeof(float);

  //~ dim3 dimGrid(nBlocks, nBlocks, 1);
  //~ dim3 dimBlock(nThreads, nThreads, 1);

  //~ cudaEventCreate(&E0); cudaEventCreate(&E1); cudaEventCreate(&E2); cudaEventCreate(&E3);

  if (PINNED) {
    // Obtiene Memoria [pinned] en el host
    //~ cudaMallocHost((float**)&h_A, numBytes); 
    //~ cudaMallocHost((float**)&h_B, convBytes); 
    //~ cudaMallocHost((float**)&h_C, numBytes); 
  }
  else {
    // Obtener Memoria en el host
    h_A = (float*) malloc(numBytes); 
    h_B = (float*) malloc(convBytes); 
    h_C = (float*) malloc(numBytes); 
  }

  // Inicializa las matrices
  InitM(N, N, h_A);
  InitM(cN, cN, h_B);
  printf("print A\n");
  print(N, N, h_A);
  printf("Print B \n");
  print(cN, cN, h_B);
  TestCM(N,N,cN,h_A,h_B,h_C);
  
  //~ cudaEventRecord(E0, 0);
  //~ cudaEventSynchronize(E0);
  //~ 
  //~ // Obtener Memoria en el device
  //~ cudaMalloc((float**)&d_A, numBytes); 
  //~ cudaMalloc((float**)&d_B, convBytes); 
  //~ cudaMalloc((float**)&d_C, numBytes); 
//~ 
  //~ // Copiar datos desde el host en el device 
  //~ cudaMemcpy(d_A, h_A, numBytes, cudaMemcpyHostToDevice);
  //~ cudaMemcpy(d_B, h_B, convBytes, cudaMemcpyHostToDevice);
//~ 
  //~ cudaEventRecord(E1, 0);
  //~ cudaEventSynchronize(E1);
  //~ 
  //~ // Ejecutar el kernel 
  //~ Kernel11<<<dimGrid, dimBlock>>>(N, cN, N, d_A, d_B, d_C);
//~ 
  //~ cudaEventRecord(E2, 0);
  //~ cudaEventSynchronize(E2);
//~ 
  //~ // Obtener el resultado desde el host 
  //~ cudaMemcpy(h_C, d_C, numBytes, cudaMemcpyDeviceToHost); 
//~ 
  //~ // Liberar Memoria del device 
  //~ cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
//~ 
  //~ cudaEventRecord(E3, 0);
  //~ cudaEventSynchronize(E3);
//~ 
  //~ cudaEventElapsedTime(&TiempoTotal,  E0, E3);
  //~ cudaEventElapsedTime(&TiempoKernel, E1, E2);
  //~ printf("\nKERNEL 11\n");
  //~ printf("Dimensiones: %dx%d\n", N, N);
  //~ printf("nThreads: %dx%d (%d)\n", nThreads, nThreads, nThreads * nThreads);
  //~ printf("nBlocks: %dx%d (%d)\n", nBlocks, nBlocks, nBlocks*nBlocks);
  //~ if (PINNED) printf("Usando Pinned Memory\n"); else printf("NO usa Pinned Memory\n");
  //~ printf("Tiempo Global: %4.6f milseg\n", TiempoTotal);
  //~ printf("Tiempo Kernel: %4.6f milseg\n", TiempoKernel);
  //~ printf("Rendimiento Global: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoTotal));
  //~ printf("Rendimiento Kernel: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoKernel));
//~ 
  //~ cudaEventDestroy(E0); cudaEventDestroy(E1); cudaEventDestroy(E2); cudaEventDestroy(E3);
//~ 
  //~ if (test == 'N')
    //~ printf ("NO TEST\n");
  //~ else  if (TestMM(N, N, N, h_A, h_B, h_C))
    //~ printf ("TEST PASS\n");
  //~ else
    //~ printf ("TEST FAIL\n");
//~ 
  //~ if (PINNED) { cudaFreeHost(h_A); cudaFreeHost(h_B); cudaFreeHost(h_C); }
  //~ else { free(h_A); free(h_B); free(h_C); }

}


void InitM(int N, int M, float *Mat) {
   int i;
   for (i=0; i<N*M; i++) 
     Mat[i] = rand() / (float) RAND_MAX;
   
}

void print(int N, int M, float *C)
{
  int i, j;
  for (i=0; i<N; i++) {
     for (j=0; j<M; j++) {
       printf("%f ", C[i*N+j]);
     }
     printf("\n");
  }
}


int TestCM(int N, int M, int P, float *A, float *B, float *C) {
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
      C[i*N+j]=acc;
     }
  print (N, M, C);
   return 1;
}

