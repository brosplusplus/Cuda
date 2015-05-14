#include <stdio.h>
#include <stdlib.h>

#define SIZE 16

#ifndef PINNED
#define PINNED 0
#endif


// Matriz por Matriz
// C(NxM) <- A(NxP) * B (PxM)

__global__ void Kernel01 (int N, int M, int P, float *A, float *B, float *C) {
	__shared__ float sA[SIZE][SIZE];
	__shared__ float sB[SIZE][SIZE];

	int bx = blockIdx.x; int by = blockIdx.y;
        int tx = threadIdx.x; int ty = threadIdx.y;
        int row = by * SIZE + ty;
        int col = bx * SIZE + tx;

	float tmp = 0.0;
	for (int m=0; m< (P/SIZE); m++) {
		sA[ty][tx] = A[row*P + m*SIZE + tx];
		sB[ty][tx] = B[col + (m*SIZE + ty)*M];
		__syncthreads();
		for (int k=0; k<SIZE; k++)
			tmp += sA[ty][k] * sB[k][tx];
		__syncthreads();
	}
	C[row*M+col] = tmp;	
}
/*__global__ vois MMkernel2 (float *dA, float *dB, float *dC, int N) {

	__shared__ float sA[size][size];
	__shared__ float sB[size][size];

	int bx = blockIdx.x; int by = blockIdx.y;
	int tx = threadIdx.x; int ty = threadIdx.y;
	int row = by * size + ty;
	int col = bx * size + tx;

	float tmp = 0.0;
	for (m=0; m< (N/size); m++) {
		sA[ty][tx] = dA[row*N + m*size + tx];
		sB[ty][tx] = dB[col + (m*size + ty)*N];
		_syncthreads();
		for (int k=0; k<size; k++)
			tmp += sA [ty][k] * sB[k][tx];
		_syncthreads();
	}
	dC[row*N+col] = tmp;
}*/


void InitM(int N, int M, float *Mat);
int TestMM(int N, int M, int P, float *A, float *B, float *C);


// Invocacion:
// ./ejecutable TAM test
// TAM es el la dimension de las matrices
// test == 'Y', comprueba que el resultado sea correcto
// test == 'N', NO comprueba que el resultado (Util para tomar tiempos)
// Por defecto, N = 2048, test == 'N'

int main(int argc, char** argv)
{
  unsigned int N, M, P;
  unsigned int numBytesM1, numBytesM2, numBytesRes;
  unsigned int nBlocks, mBlocks, nThreads;
 
  float TiempoTotal, TiempoKernel;
  cudaEvent_t E0, E1, E2, E3;

  float *h_A, *h_B, *h_C;
  float *d_A, *d_B, *d_C;

  char test;

  // Dimension de las matrices NxN y comprobacion resultado
  if (argc == 1)      { test = 'N'; N = 2048; M = 2048; P = 2048; }
  else if (argc == 2) { test = 'N'; N = atoi(argv[1]); M = N; P = N; }
  else if (argc == 3) { test = *argv[2]; N = atoi(argv[1]);M = N; P = N; }
  else if (argc == 4) { test = 'N'; N = atoi(argv[1]); P = atoi(argv[2]); M = atoi(argv[3]);}
  else if (argc == 5) { test = *argv[4]; N = atoi(argv[1]); P = atoi(argv[2]); M = atoi(argv[3]);}
  else { printf("Usage: ./exe TAM1x TAM1y/2x TAM2y test\n"); exit(0); }

  // numero de Threads en cada dimension 
  nThreads = SIZE;

  // numero de Blocks en cada dimension 
  nBlocks = N/nThreads; 
  mBlocks = M/nThreads;

  printf("%d:%d, %d:%d\n", N, nBlocks, M, mBlocks);
  
  
  numBytesM1 = N * P * sizeof(float);
  numBytesM2 = M * P * sizeof(float);
  numBytesRes = M * N * sizeof(float);

  dim3 dimGrid(nBlocks, mBlocks, 1);
  dim3 dimBlock(nThreads, nThreads, 1);

  cudaEventCreate(&E0);
  cudaEventCreate(&E1);
  cudaEventCreate(&E2);
  cudaEventCreate(&E3);

  if (PINNED) {
    // Obtiene Memoria [pinned] en el host
    cudaMallocHost((float**)&h_A, numBytesM1); 
    cudaMallocHost((float**)&h_B, numBytesM2); 
    cudaMallocHost((float**)&h_C, numBytesRes); 
  }
  else {
    // Obtener Memoria en el host
    h_A = (float*) malloc(numBytesM1); 
    h_B = (float*) malloc(numBytesM2); 
    h_C = (float*) malloc(numBytesRes); 
  }

  // Inicializa las matrices
  InitM(N, P, h_A);
  InitM(P, M, h_B);

  cudaEventRecord(E0, 0);
  cudaEventSynchronize(E0);
  
  // Obtener Memoria en el device
  cudaMalloc((float**)&d_A, numBytesM1); 
  cudaMalloc((float**)&d_B, numBytesM2); 
  cudaMalloc((float**)&d_C, numBytesRes); 

  // Copiar datos desde el host en el device 
  cudaMemcpy(d_A, h_A, numBytesM1, cudaMemcpyHostToDevice);
  cudaMemcpy(d_B, h_B, numBytesM2, cudaMemcpyHostToDevice);

  cudaEventRecord(E1, 0);
  cudaEventSynchronize(E1);
  
  // Ejecutar el kernel 
  Kernel01<<<dimGrid, dimBlock>>>(N, P, M, d_A, d_B, d_C);

  cudaEventRecord(E2, 0);
  cudaEventSynchronize(E2);

  // Obtener el resultado desde el host 
  cudaMemcpy(h_C, d_C, numBytesRes, cudaMemcpyDeviceToHost); 

  // Liberar Memoria del device 
  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_C);

  cudaEventRecord(E3, 0);
  cudaEventSynchronize(E3);

  cudaEventElapsedTime(&TiempoTotal,  E0, E3);
  cudaEventElapsedTime(&TiempoKernel, E1, E2);
  printf("\nKERNEL 01\n");
  printf("Dimensiones: %dx%d\n", N, N);
  printf("nThreads: %dx%d (%d)\n", nThreads, nThreads, nThreads * nThreads);
  printf("nBlocks: %dx%d (%d)\n", nBlocks, nBlocks, nBlocks*nBlocks);
  if (PINNED) printf("Usando Pinned Memory\n");
         else printf("NO usa Pinned Memory\n");
  printf("Tiempo Global: %4.6f milseg\n", TiempoTotal);
  printf("Tiempo Kernel: %4.6f milseg\n", TiempoKernel);
  printf("Rendimiento Global: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoTotal));
  printf("Rendimiento Kernel: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoKernel));

  cudaEventDestroy(E0); cudaEventDestroy(E1); cudaEventDestroy(E2); cudaEventDestroy(E3);

  if (test == 'N')
    printf ("NO TEST\n");
  else  if (TestMM(N, N, N, h_A, h_B, h_C))
    printf ("TEST PASS\n");
  else
    printf ("TEST FAIL\n");

  if (PINNED) {
    cudaFreeHost(h_A); cudaFreeHost(h_B); cudaFreeHost(h_C);
  }
  else {
    free(h_A); free(h_B); free(h_C);
  }

}
