#include "../common/gen-rand-matrix.h"
#include "../common/sorted-dynamic-array.h"
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

// cuBLAS has no custom kernel to dummy-ify.
// This benchmarks only the D2H transfer that cuBLAS matmul uses.
// The timing window matches the original: D2H copy only.
// (The original times cublasSgemm + D2H; this removes cublasSgemm.)

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
