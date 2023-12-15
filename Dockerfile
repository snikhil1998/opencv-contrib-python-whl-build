ARG CUDA_VERSION=12.2.2
ARG CUDNN_VERSION=8
ARG UBUNTU_VERSION=22.04
FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-devel-ubuntu${UBUNTU_VERSION}

# Releases found in https://github.com/opencv/opencv-python/releases
ARG OPENCV_PYTHON_RELEASE=4.8.1.78

# Install the necessary packages
RUN apt update && \
    apt upgrade -y && \
    apt install -y build-essential cmake pkg-config && \
    apt install -y python3-dev python3-pip && \
    apt install -y curl jq git && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN TAG=$(curl -s https://api.github.com/repos/opencv/opencv-python/releases | jq -r --arg RELEASE ${OPENCV_PYTHON_RELEASE} '.[] | select(.name==$RELEASE) | .tag_name') && \
    git clone --recurse-submodules https://github.com/opencv/opencv-python.git --branch ${TAG}

WORKDIR /opencv-python/opencv/build

# For verbose output during build
ARG VERBOSE=1

# Enables CUDA and cuDNN support
ARG ENABLE_CONTRIB=1

# Uncomment when the .whl file is required for server environments like docker
#ARG ENABLE_HEADLESS=1

# Builds on latest commit of each submodule, uncomment only when building on stable release of submodules fails
#ARG ENABLE_ROLLING=1

# Arguments for cmake, used by `pip wheel`
ARG AMAKE_ARGS="-DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DINSTALL_PYTHON_EXAMPLES=ON \
    -DINSTALL_C_EXAMPLES=OFF \
    -DOPENCV_ENABLE_NONFREE=ON \
    -DWITH_CUDA=ON \
    -DWITH_CUDNN=ON \
    -DOPENCV_DNN_CUDA=ON \
    -DENABLE_FAST_MATH=1 \
    -DCUDA_FAST_MATH=1 \
    -DCUDA_ARCH_BIN=7.5 \
    -DWITH_CUBLAS=1 \
    -DOPENCV_EXTRA_MODULES_PATH=/opencv-python/opencv_contrib/modules \
    -DHAVE_opencv_python3=ON \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DBUILD_EXAMPLES=ON"

# Build the required .whl files
RUN pip3 wheel /opencv-python --verbose --wheel-dir /opencv_cuda_cudnn_whls
