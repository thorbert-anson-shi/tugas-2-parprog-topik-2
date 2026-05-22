#include "gen-rand-matrix.h"
#include "sorted-dynamic-array.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define TILE_WIDTH 20

__global__ void square_matmul(float *a, float *b, float *c, int N) {
  int bx = blockIdx.x;
  int by = blockIdx.y;

  int tx = threadIdx.x;
  int ty = threadIdx.y;

  int i = by * blockDim.y + ty;
  int j = bx * blockDim.x + tx;

  __shared__ float sh_A[TILE_WIDTH][TILE_WIDTH];
  __shared__ float sh_B[TILE_WIDTH][TILE_WIDTH];

  float value = 0;
  for (int phase = 0; phase < N / TILE_WIDTH; phase++) {
    sh_A[ty][tx] = a[N * i + phase * TILE_WIDTH + tx];
    sh_B[ty][tx] = b[(phase * TILE_WIDTH + ty) * N + j];
    __syncthreads();

    for (int k = 0; k < TILE_WIDTH; k++) {
      value += sh_A[ty][k] * sh_B[k][tx];
    }
    __syncthreads();
  }

  c[i * N + j] = value;
}

int main() {
  int num_iter;
  scanf("Number of iterations: %d\n", &num_iter);

  int n;
  scanf("Matrix size: %d\n", &n);

  int num_elements = pow(n, 2);

  double *times = (double *)malloc(n * sizeof(double));

  // For now, all elements are stored in CPU memory
  float *a = (float *)malloc(num_elements * sizeof(float));
  float *b = (float *)malloc(num_elements * sizeof(float));

  gen_rand_sq_matrix(a, b, num_elements);

  // Iterate n times for consistency
  for (int i = 0; i < num_iter; i++) {
    float *h_a = (float *)malloc(num_elements * sizeof(float));
    float *h_b = (float *)malloc(num_elements * sizeof(float));

    memcpy(h_a, a, num_elements * sizeof(float));
    memcpy(h_b, b, num_elements * sizeof(float));

    // Move these bad boys to GPU memory
    float *d_a, *d_b, *d_c;
    cudaMalloc(&d_a, num_elements * sizeof(float));
    cudaMalloc(&d_b, num_elements * sizeof(float));
    cudaMalloc(&d_c, num_elements * sizeof(float));

    int grid_size = (n + TILE_WIDTH - 1) / TILE_WIDTH;
    dim3 gridDim(grid_size, grid_size);
    dim3 blockDim(TILE_WIDTH, TILE_WIDTH);

    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    cudaMemcpy(d_a, h_a, num_elements * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, num_elements * sizeof(float), cudaMemcpyHostToDevice);

    square_matmul<<<gridDim, blockDim>>>(d_a, d_b, d_c, n);

    float *answer = (float *)malloc(num_elements * sizeof(float));
    cudaMemcpy(answer, d_c, num_elements * sizeof(float),
               cudaMemcpyDeviceToHost);

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    free(h_a);
    free(h_b);
    free(answer);

    clock_gettime(CLOCK_MONOTONIC, &end);

    double elapsed_ms = (end.tv_sec - start.tv_sec) * 1000.0 +
                        (end.tv_nsec - start.tv_nsec) / 1000000.0;

    insert_sorted(times, i, elapsed_ms);
  }

  print_stats(times, num_iter);
}
