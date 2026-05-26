NVCC := nvcc
NVCC_FLAGS := -lcublas
BUILD_DIR := build
SRC_DIR := src

COMMON_SRC := $(SRC_DIR)/common/gen-rand-matrix.c \
              $(SRC_DIR)/common/sorted-dynamic-array.c \
              $(SRC_DIR)/common/create-answer-key.cu

.PHONY: all clean

all: $(BUILD_DIR)/matmul-tiled $(BUILD_DIR)/matmul-naive $(BUILD_DIR)/matmul-cublas $(BUILD_DIR)/matmul-sequential


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/matmul-tiled: $(SRC_DIR)/tiled/matmul.cu $(COMMON_SRC) \
                            $(SRC_DIR)/common/verify-matrix-equality.c | $(BUILD_DIR)
	$(NVCC) $(NVCC_FLAGS) -o $@ $^

$(BUILD_DIR)/matmul-naive: $(SRC_DIR)/naive/matmul-global.cu $(COMMON_SRC) \
                            $(SRC_DIR)/common/verify-matrix-equality.c | $(BUILD_DIR)
	$(NVCC) $(NVCC_FLAGS) -o $@ $^

$(BUILD_DIR)/matmul-sequential: $(SRC_DIR)/sequential/matmul-sequential.cu $(COMMON_SRC) \
                            $(SRC_DIR)/common/verify-matrix-equality.c | $(BUILD_DIR)
	$(NVCC) $(NVCC_FLAGS) -o $@ $^

$(BUILD_DIR)/matmul-cublas: $(SRC_DIR)/cublas/matmul-cublas.cu $(COMMON_SRC) | $(BUILD_DIR)
	$(NVCC) $(NVCC_FLAGS) -o $@ $^

clean:
	rm -rf $(BUILD_DIR)
	rm -f matmul-tiled matmul-naive matmul-cublas matmul-sequential 
