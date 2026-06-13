# Stage 1: Build llama.cpp with STQ kernel
FROM nvidia/cuda:13.1.1-devel-ubuntu24.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake build-essential && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN cmake -B build \
        -DGGML_CUDA=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DGGML_CUDA_PEER_MAX_BATCH_SIZE=128 \
        -DGGML_CUDA_FA=ON \
        -DGGML_CUDA_MMLU=ON \
        -DGGML_CUDA_DMMV_Q=OFF && \
    cmake --build build --config Release -j$(nproc)

# Stage 2: Runtime
FROM nvidia/cuda:13.1.1-runtime-ubuntu24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /src/build/bin/llama-server /usr/local/bin/
COPY --from=builder /src/build/lib/*.so* /usr/local/lib/ 2>/dev/null || true

EXPOSE 8080

CMD ["llama-server"]
