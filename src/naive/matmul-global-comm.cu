#include "../common/gen-rand-matrix.h"
#include "../common/sorted-dynamic-array.h"
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define TILE_WIDTH 32

// Dummy kernel: same global memory access pattern as naive matmul,
// but no multiply-accumulate. Purely measures global memory reads.
__global__ void dummy_matmul(float *a, float *b, float *c, int N) {
  int bx = blockIdx.x;
  int by = blockIdx.y;

  int tx = threadIdx.x;
  int ty = threadIdx.y;

  int i = by * blockDim.y + ty;
  int j = bx * blockDim.x + tx;

  if (i < N && j < N) {
    float value = 0;

    for (int k = 0; k < N; k++) {
      value += a[i * N + k] + b[k * N + j];
    }

    c[i * N + j] = value;
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
