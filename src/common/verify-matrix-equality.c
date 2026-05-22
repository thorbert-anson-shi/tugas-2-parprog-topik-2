#include <math.h>
#include <stdbool.h>
#include <stdio.h>

bool verify_matrix_equality(float *a, float *b, int len) {
  for (int i = 0; i < len; i++) {
    if (fabs(a[i] - b[i]) > 0.01) {
      printf("%f %f", a[i], b[i]);
      return false;
    }
  }
  return true;
}
