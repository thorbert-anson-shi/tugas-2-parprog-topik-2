#include <stdbool.h>

bool verify_matrix_equality(float *a, float *b, int len) {
  for (int i = 0; i < len; i++) {
    if (abs(a[i] - b[i]) > 0.01) {
      return false;
    }
  }
  return true;
}
