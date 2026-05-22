#ifndef SORTED_DYNAMIC_ARRAY_H
#define SORTED_DYNAMIC_ARRAY_H

#ifdef __cplusplus
extern "C" {
#endif

void insert_sorted(double *arr, int occupiedLen, double inserted);
double get_percentile(double *times, int arr_len, int percentile);
double get_mean(double *times, int arr_len);
double get_trimmed_mean(double *times, int trimmedFromTails, int arr_len);
double get_best(double *times);
double get_worst(double *times, int arr_len);
void print_stats(double *times, int arr_len);

#ifdef __cplusplus
}
#endif

#endif
