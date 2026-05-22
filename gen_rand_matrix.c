void gen_rand_sq_matrix(float *h_a, float *h_b, int num_elements) {
  for (int i = 0; i < num_elements; i++) {
    h_a[i] = (i + 96) % (i + 1);
    h_b[i] = (i + 30) % (i + 1);
  }
}
