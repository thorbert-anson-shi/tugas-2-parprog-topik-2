#include "../common/gen-rand-matrix.h"
#include "../common/sorted-dynamic-array.h"
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

// Dummy kernel: same global memory access pattern as sequential matmul,
// but no multiply-accumulate. Single thread, pure global memory reads.
__global__ void dummy_seq_matmul(float *a, float *b, float *c, int N) {
  if (threadIdx.x == 0) {
    for (int i = 0; i < N; i++) {
      for (int j = 0; j < N; j++) {
        float sum = 0.0f;
        for (int k = 0; k < N; k++) {
          sum += a[i * N + k] + b[k * N + j];
        }
        c[i * N + j] = sum;
      }
    }
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

  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  for (int i = 0; i < num_iter; i++) {
    cudaEventRecord(start);

    dummy_seq_matmul<<<1, 1>>>(d_a, d_b, d_c, n);

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
