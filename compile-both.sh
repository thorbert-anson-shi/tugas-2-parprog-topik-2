#!/bin/bash

echo "Compiling matmul-tiled..."
if nvcc -lcublas -o matmul-tiled matmul.cu gen-rand-matrix.c sorted-dynamic-array.c verify-matrix-equality.c; then
  echo "✓ matmul-tiled compiled successfully"
else
  echo "✗ matmul-tiled compilation failed"
fi

echo "Compiling matmul-cublas..."
if nvcc -lcublas -o matmul-cublas matmul-cublas.cu gen-rand-matrix.c sorted-dynamic-array.c; then
  echo "✓ matmul-cublas compiled successfully"
else
  echo "✗ matmul-cublas compilation failed"
fi
