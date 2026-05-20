#include <math.h>
#include <stdio.h>
#include <stdlib.h>

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
  int n = 100;
  // scanf("%d\n", &n);

  int num_elements = pow(n, 2);

  // For now, all elements are stored in CPU memory
  float *h_a = (float *)malloc(num_elements * sizeof(float));
  float *h_b = (float *)malloc(num_elements * sizeof(float));

  // Fill the elements on the host side
  for (int i = 0; i < num_elements; i++) {
    h_a[i] = (i + 96) % (i + 1);
    h_b[i] = (i + 30) % (i + 1);
  }

  // Move these bad boys to GPU memory
  float *d_a, *d_b, *d_c;
  cudaMalloc(&d_a, num_elements * sizeof(float));
  cudaMalloc(&d_b, num_elements * sizeof(float));
  cudaMalloc(&d_c, num_elements * sizeof(float));

  cudaMemcpy(d_a, h_a, num_elements * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_b, h_b, num_elements * sizeof(float), cudaMemcpyHostToDevice);

  int grid_size = ceilf((float)n / TILE_WIDTH);
  dim3 gridDim(grid_size, grid_size);
  dim3 blockDim(TILE_WIDTH, TILE_WIDTH);

  square_matmul<<<gridDim, blockDim>>>(d_a, d_b, d_c, n);

  float *answer = (float *)malloc(num_elements * sizeof(float));
  cudaMemcpy(answer, d_c, num_elements * sizeof(float), cudaMemcpyDeviceToHost);
  //
  // for (int i = 0; i < num_elements; i++) {
  //   printf("%f ", answer[i]);
  //   if (i % n == n - 1) {
  //     printf("\n");
  //   }
  // }
}
