#include <math.h>
#include <stdio.h>
#include <stdlib.h>

void verify_matrix_equality(float *a, float *b, int len) {
  for (int i = 0; i < len; i++) {
    // 1. Explicitly catch if either value is NaN
    if (isnan(a[i]) || isnan(b[i])) {
      printf("Verification FAILED at index %d: One or both values are NaN! (a: "
             "%f, b: %f)\n",
             i, a[i], b[i]);
      exit(1);
    }

    // 2. Check the delta for normal floating-point differences
    if (fabs(a[i] - b[i]) > 0.01) {
      printf("Verification FAILED at index %d: Target %f != Expected %f\n", i,
             a[i], b[i]);
      exit(1);
    }
  }
  printf("Verification PASSED!\n");
}
