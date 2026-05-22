#include "gen_rand_matrix.h"
#include "sorted_dynamic_array.h"
#include <cublas_v2.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main() {
  int num_iter;
  scanf("%d", &num_iter);

  int n = 100;
  int num_elements = n * n;

  double *times = (double *)malloc(n * sizeof(double));

  float *a = (float *)malloc(num_elements * sizeof(float));
  float *b = (float *)malloc(num_elements * sizeof(float));

  gen_rand_sq_matrix(a, b, num_elements);

  cublasHandle_t handle;
  cublasCreate(&handle);

  float alpha = 1.0f;
  float beta = 0.0f;

  // Iterate n times for consistency
  for (int i = 0; i < num_iter; i++) {
    float *h_a = (float *)malloc(num_elements * sizeof(float));
    float *h_b = (float *)malloc(num_elements * sizeof(float));

    memcpy(h_a, a, num_elements * sizeof(float));
    memcpy(h_b, b, num_elements * sizeof(float));

    float *d_a, *d_b, *d_c;
    cudaMalloc(&d_a, num_elements * sizeof(float));
    cudaMalloc(&d_b, num_elements * sizeof(float));
    cudaMalloc(&d_c, num_elements * sizeof(float));

    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    cudaMemcpy(d_a, h_a, num_elements * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, num_elements * sizeof(float), cudaMemcpyHostToDevice);

    // cuBLAS is column-major; for row-major A, B we swap operands
    // Computes C (col-major) = B (col-major) * A (col-major)
    // which yields C_row = A_row * B_row
    cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, n, n, n, &alpha, d_b, n, d_a,
                n, &beta, d_c, n);

    float *h_c = (float *)malloc(num_elements * sizeof(float));
    cudaMemcpy(h_c, d_c, num_elements * sizeof(float), cudaMemcpyDeviceToHost);

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    free(h_a);
    free(h_b);
    free(h_c);

    clock_gettime(CLOCK_MONOTONIC, &end);

    double elapsed_ms = (end.tv_sec - start.tv_sec) * 1000.0 +
                        (end.tv_nsec - start.tv_nsec) / 1000000.0;

    insert_sorted(times, i, elapsed_ms);
  }

  cublasDestroy(handle);

  print_stats(times, num_iter);
}
