#include <stdio.h>
#include <stdlib.h>

#define SIZE 16

#ifndef PINNED
#define PINNED 0
#endif

// Matriz por Matriz
// C(NxM) <- A(NxP) * B (PxM)
//
//
// Este codigo ya ha sido probado. Simplemente se ha modificado para poder 
// obtener el rendimiento para diferentes dimensiones de problema.
// En este caso no se comprueba el resultado
//

__global__ void Kernel01 (int N, int M, int P, float *A, float *B, float *C) {

  int row = blockIdx.y * blockDim.y + threadIdx.y;
  int col = blockIdx.x * blockDim.x + threadIdx.x;
  if (row < N && col < M) {
    float tmp = 0.0;
    for (int k=0; k<P; k++)
      tmp += A[row*P+k] * B[k*N+col];
    C[row*N+col] = tmp;
  }
}



void InitM(int N, int M, float *Mat);
int TestMM(int N, int M, int P, float *A, float *B, float *C);


// Invocacion:
// ./ejecutable TAM-min TAM-max inc
// TAM-min es la dimension incial (valor por defecto 100)
// TAM-max es la dimension final  (valor por defecto 4000)
// inc es el incremento (valor por defecto 100)

int main(int argc, char** argv)
{
  unsigned int N;
  unsigned int numBytes;
  unsigned int nBlocks, nThreads;
 
  float TiempoTotal, TiempoKernel;
  cudaEvent_t E0, E1, E2, E3;

  float *h_A, *h_B, *h_C;
  float *d_A, *d_B, *d_C;

  int tamINI, tamMAX, inc; 

  if (argc == 1)      { tamINI = 100; tamMAX = 4000; inc = 100; }
  else if (argc == 4) { tamINI = atoi(argv[1]); tamMAX = atoi(argv[2]); inc = atoi(argv[3]); }
  else { printf("Usage: ./exe tamINI tamMAX inc\n"); exit(0); }

  for (N = tamINI; N<=tamMAX; N=N+inc) {
    // numero de Threads en cada dimension 
    nThreads = SIZE;

    // numero de Blocks en cada dimension 
    nBlocks = (N+nThreads-1)/nThreads; 
  
    numBytes = N * N * sizeof(float);

    dim3 dimGrid(nBlocks, nBlocks, 1);
    dim3 dimBlock(nThreads, nThreads, 1);

    cudaEventCreate(&E0);
    cudaEventCreate(&E1);
    cudaEventCreate(&E2);
    cudaEventCreate(&E3);

    if (PINNED) {
      // Obtiene Memoria [pinned] en el host
      cudaMallocHost((float**)&h_A, numBytes); 
      cudaMallocHost((float**)&h_B, numBytes); 
      cudaMallocHost((float**)&h_C, numBytes); 
    }
    else {
      // Obtener Memoria en el host
      h_A = (float*) malloc(numBytes); 
      h_B = (float*) malloc(numBytes); 
      h_C = (float*) malloc(numBytes); 
    }

    // Inicializa las matrices
    InitM(N, N, h_A);
    InitM(N, N, h_B);

    cudaEventRecord(E0, 0);
    cudaEventSynchronize(E0);
  
    // Obtener Memoria en el device
    cudaMalloc((float**)&d_A, numBytes); 
    cudaMalloc((float**)&d_B, numBytes); 
    cudaMalloc((float**)&d_C, numBytes); 

    // Copiar datos desde el host en el device 
    cudaMemcpy(d_A, h_A, numBytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, numBytes, cudaMemcpyHostToDevice);

    cudaEventRecord(E1, 0);
    cudaEventSynchronize(E1);
  
    // Ejecutar el kernel 
    Kernel01<<<dimGrid, dimBlock>>>(N, N, N, d_A, d_B, d_C);

    cudaEventRecord(E2, 0);
    cudaEventSynchronize(E2);

    // Obtener el resultado desde el host 
    cudaMemcpy(h_C, d_C, numBytes, cudaMemcpyDeviceToHost); 

    // Liberar Memoria del device 
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    cudaEventRecord(E3, 0);
    cudaEventSynchronize(E3);

    cudaEventElapsedTime(&TiempoTotal,  E0, E3);
    cudaEventElapsedTime(&TiempoKernel, E1, E2);
  
    printf("%d: ", N);
    printf("%4.2f ", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoTotal));
    printf("%4.2f \n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoKernel));

    cudaEventDestroy(E0); cudaEventDestroy(E1); cudaEventDestroy(E2); cudaEventDestroy(E3);

    if (PINNED) { cudaFreeHost(h_A); cudaFreeHost(h_B); cudaFreeHost(h_C); }
    else { free(h_A); free(h_B); free(h_C); }
  }
}


void InitM(int N, int M, float *Mat) {
   int i;
   for (i=0; i<N*M; i++) 
     Mat[i] = rand() / (float) RAND_MAX;
   
}

int error(float a, float b) {
  float tmp;

  tmp = abs(a-b) / abs(min(a,b));

  if (tmp > 0.0001) return 1;
  else  return 0;

}

int TestMM(int N, int M, int P, float *A, float *B, float *C) {
   int i, j, k;
   float tmp;
   for (i=0; i<N; i++)
     for (j=0; j<M; j++) {
       tmp = 0.0;
       for (k=0; k<P; k++) 
         tmp = tmp + A[i*P+k] * B[k*M+j]; 
       if (error(tmp, C[i*M+j])) {
         printf ("%d:%d: %f - %f = %f \n", i, j, tmp, C[i*M+j], abs(tmp - C[i*M+j]));
         return 0;
       }
     }
   
   return 1;
}

