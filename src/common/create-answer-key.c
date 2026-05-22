#include <cublas_v2.h>
#include <math.h>

void create_answer_key(float *answer_key, int n) {
  int arr_len = pow(n, 2);

  // Create answer key to verify correctness
  cublasHandle_t handle;
  cublasCreate(&handle);
  float alpha = 1.0f;
  float beta = 0.0f;

  float *t_a, *t_b, *t_c;
  cudaMalloc(&t_a, arr_len * sizeof(float));
  cudaMalloc(&t_b, arr_len * sizeof(float));
  cudaMalloc(&t_c, arr_len * sizeof(float));

  cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, n, n, n, &alpha, t_b, n, t_a, n,
              &beta, t_c, n);
  answer_key = (float *)malloc(arr_len * sizeof(float));
  cudaMemcpy(answer_key, t_c, arr_len * sizeof(float), cudaMemcpyDeviceToHost);
}
