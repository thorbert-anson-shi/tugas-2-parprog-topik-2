#include "../common/gen-rand-matrix.h"
#include "../common/sorted-dynamic-array.h"
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define TILE_WIDTH 32

// Dummy kernel: same global→shared memory access pattern as tiled matmul.
// Loads tiles into shared memory, reads them back, but does NO arithmetic.
// Measures pure global→shared transfer + shared memory access time.
__global__ void dummy_matmul(float *a, float *b, float *c, int N) {
  int bx = blockIdx.x;
  int by = blockIdx.y;

  int tx = threadIdx.x;
  int ty = threadIdx.y;

  int i = by * blockDim.y + ty;
  int j = bx * blockDim.x + tx;

  __shared__ float sh_A[TILE_WIDTH][TILE_WIDTH];
  __shared__ float sh_B[TILE_WIDTH][TILE_WIDTH];

  volatile float sink = 0.0f;
  for (int phase = 0; phase < (N + TILE_WIDTH - 1) / TILE_WIDTH; phase++) {
    if (phase * TILE_WIDTH + tx >= N || i >= N) {
      sh_A[ty][tx] = 0.0f;
    } else {
      sh_A[ty][tx] = a[N * i + phase * TILE_WIDTH + tx];
    }

    if (phase * TILE_WIDTH + ty >= N || j >= N) {
      sh_B[ty][tx] = 0.0f;
    } else {
      sh_B[ty][tx] = b[(phase * TILE_WIDTH + ty) * N + j];
    }

    __syncthreads();

    // Read from shared memory but do NOT compute — prevents optimization
    sink = sh_A[ty][tx];
    sink = sh_B[ty][tx];

    __syncthreads();
  }

  if (i < N && j < N) {
    c[i * N + j] = sink;
  }
}

int main() {
  int num_iter;
  printf("Number of iterations: ");
  scanf("%d", &num_iter);

  int n;
  printf("Matrix size: ");
  scanf("%d", &n);

  int num_elements = n * n;

  double *times = (double *)malloc(num_iter * sizeof(double));

  float *a = (float *)malloc(num_elements * sizeof(float));
  float *b = (float *)malloc(num_elements * sizeof(float));
  float *answer = (float *)malloc(num_elements * sizeof(float));

  float *d_a, *d_b, *d_c;
  cudaMalloc(&d_a, num_elements * sizeof(float));
  cudaMalloc(&d_b, num_elements * sizeof(float));
  cudaMalloc(&d_c, num_elements * sizeof(float));

  gen_rand_sq_matrix(a, b, num_elements);

  cudaMemcpy(d_a, a, num_elements * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_b, b, num_elements * sizeof(float), cudaMemcpyHostToDevice);

  int grid_size = (n + TILE_WIDTH - 1) / TILE_WIDTH;
  dim3 gridDim(grid_size, grid_size);
  dim3 blockDim(TILE_WIDTH, TILE_WIDTH);

  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  for (int i = 0; i < num_iter; i++) {
    cudaEventRecord(start);

    dummy_matmul<<<gridDim, blockDim>>>(d_a, d_b, d_c, n);

    cudaMemcpy(answer, d_c, num_elements * sizeof(float),
               cudaMemcpyDeviceToHost);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float elapsed_ms;
    cudaEventElapsedTime(&elapsed_ms, start, stop);

    insert_sorted(times, i, (double)elapsed_ms);
  }

  cudaEventDestroy(start);
  cudaEventDestroy(stop);

  cudaFree(d_a);
  cudaFree(d_b);
  cudaFree(d_c);
  free(a);
  free(b);
  free(answer);

  print_stats(times, num_iter);
}
