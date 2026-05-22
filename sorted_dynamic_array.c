#include <stdio.h>
#include <string.h>

int binary_search(double *arr, int arr_len, double inserted) {
  int l = 0;
  int r = arr_len;

  while (l < r) {
    int mid = l + (r - l) / 2;
    if (inserted < arr[mid]) {
      r = mid;
    } else {
      l = mid + 1;
    }
  }

  return l;
}

void insert_sorted(double *arr, int occupiedLen, double inserted) {
  int insertIdx = binary_search(arr, occupiedLen, inserted);

  int numEleMoved = occupiedLen - insertIdx;
  memmove(&arr[insertIdx + 1], &arr[insertIdx], numEleMoved * sizeof(double));

  arr[insertIdx] = inserted;
}

double get_percentile(double *times, int arr_len, int percentile) {
  int itemIdx = arr_len * percentile / 100;

  return times[itemIdx];
}

double get_mean(double *times, int arr_len) {
  double sum = 0;
  for (int i = 0; i < arr_len; i++) {
    sum += times[i];
  }

  return sum / arr_len;
}

double get_trimmed_mean(double *times, int trimmedFromTails, int arr_len) {
  double *slice = times + trimmedFromTails;
  int numElements = arr_len - 2 * trimmedFromTails;

  return get_mean(slice, numElements);
}

double get_best(double *times) { return times[0]; }
double get_worst(double *times, int arr_len) { return times[arr_len - 1]; }

float ms_to_s(double time_in_ms) { return time_in_ms / 1e3; }

void print_stats(double *times, int arr_len) {
  float mean = ms_to_s(get_mean(times, arr_len));
  float trimmedMean = ms_to_s(get_trimmed_mean(times, 10, arr_len));
  float p95 = ms_to_s(get_percentile(times, arr_len, 95));
  float p50 = ms_to_s(get_percentile(times, arr_len, 50));
  float worst = ms_to_s(get_best(times));
  float best = ms_to_s(get_worst(times, arr_len));

  printf("mean: %.3f\n", mean);
  printf("trimmed: %.3f\n", trimmedMean);
  printf("p95: %.3f\n", p95);
  printf("p50: %.3f\n", p50);
  printf("worst: %.3f\n", worst);
  printf("best: %.3f\n", best);
}
