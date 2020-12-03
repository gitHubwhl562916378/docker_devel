From 192.168.2.100:5000/nvidia/cuda:10.2-cudnn8-devel-ubuntu18.04

ARG USERNAME=osmagic
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive
COPY sources.list /etc/apt/
#更新源，忽略更新不了的源地址错误
RUN apt-get update || true

# create non root user
RUN if [ $(getent passwd $USERNAME) ]; then \ 
        # If exists, see if we need to tweak the GID/UID
        if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then \
            groupmod --gid $USER_GID $USERNAME \
            && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
            && chown -R $USER_UID:$USER_GID /home/$USERNAME; \
        fi; \
    else \
        # Otherwise ccreate the non-root user
        groupadd --gid $USER_GID $USERNAME \
        && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
        # Add sudo support for the non-root user
        && apt-get install -y sudo \
        && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
        && chmod 0440 /etc/sudoers.d/$USERNAME; \
    fi

#install cmake
COPY cmake-3.14.4-Linux-x86_64.sh /tmp/
RUN cd /tmp && \
    chmod +x cmake-3.14.4-Linux-x86_64.sh && \
    ./cmake-3.14.4-Linux-x86_64.sh --prefix=/usr/local --exclude-subdir --skip-license && \
    rm ./cmake-3.14.4-Linux-x86_64.sh

#install common depencies
RUN apt-get install -y --no-install-recommends vim \
    libsdl2-dev libgtk2.0-dev pkg-config python-dev python-numpy \
    libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev \
    libdc1394-22-dev gdb vim git libssl-dev libmysql++-dev libboost-all-dev \
    liblas-dev libwebsocketpp-dev libcrossguid-dev libssl-dev openssl1.0

#install cuda pattch
COPY cuda_10.2.1_linux.run /tmp/
RUN cd /tmp && \
    sh cuda_10.2.1_linux.run --silent && \
    rm cuda_10.2.1_linux.run

#install nvidia-video-sdk 映射的so没有libnvcuvid.so
COPY Video_Codec_SDK/include/* /usr/local/cuda/include
RUN cd /usr/lib/x86_64-linux-gnu && ln -s libnvcuvid.so.1 libnvcuvid.so \
                                 && ln -s libnvidia-encode.so.1 libnvidia-encode.so

#install cpprestsdk
RUN cd /tmp && \
    git clone http://wanghualin:12345678@192.168.2.100:8888/KLAI/libcpprest.git && \
    cd libcpprest && mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/cpprest-sdk -DBUILD_SAMPLES=OFF -DBUILD_TESTS=OFF && \
    make -j6 && make install && cd /tmp && rm libcpprest -r

#install ffmpeg with nvidia-video-sdk
RUN cd /tmp && \
    git clone http://wanghualin:12345678@192.168.2.100:8888/KLAI/FFmpeg.git && \
    cd FFmpeg/nv-codec-headers && make && make install && cd .. && \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    ./configure --prefix=/usr/local/ffmpeg-4.3 \
    --enable-debug \
    --enable-shared \
    --disable-static \
    --arch=x86_64 \
    --enable-stripping \
    --enable-optimizations \
    --disable-x86asm \
    --enable-asm \
    --disable-iconv \
    --extra-cflags=-I./nv-codec-headers/include \
    --extra-cflags=-I/usr/local/cuda/include \
    --extra-ldflags=-L/usr/local/cuda/lib64 \
    --disable-schannel \
    --disable-xlib \
    --disable-zlib \
    --enable-protocol=file \
    --enable-cuda-nvcc \
    --enable-cuda \
    --enable-cuvid \
    --enable-nvenc \
    --enable-nonfree \
    --enable-libnpp \
    --enable-outdev=sdl2 \
    --enable-nonfree \
    --enable-version3 \
    --enable-gpl \
    --enable-ffmpeg \
    --enable-ffplay && \
    make -j6 && make install && cd /tmp && rm FFmpeg -r

#install fmt
RUN cd /tmp && \
    git clone http://wanghualin:12345678@192.168.2.100:8888/KLAI/fmt.git && \
    cd fmt && mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/fmt -DBUILD_SHARED_LIBS=ON -DFMT_TEST=OFF -DFMT_DOC=OFF && \
    make -j6 && make install && cd /tmp && rm fmt -r

#install jsoncpp
RUN cd /tmp && \
    git clone http://wanghualin:12345678@192.168.2.100:8888/KLAI/json-cpp.git && \
    cd json-cpp && mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/jsoncpp-1.9.4 -DBUILD_STATIC_LIBS=OFF -DJSONCPP_WITH_TESTS=OFF && \
    make -j6 && make install && cd /tmp && rm json-cpp -r

#install live555
RUN cd /tmp && \
    git clone http://wanghualin:12345678@192.168.2.100:8888/KLAI/live555.git && \
    cd live555 && ./genMakefiles linux-with-shared-libraries && \
    make -j6 && make install && cd /tmp && rm live555 -r

#install poco
RUN cd /tmp && \
    git clone http://wanghualin:12345678@192.168.2.100:8888/KLAI/Poco1.10.1.git && \
    cd Poco1.10.1 && mkdir cmake_build && cd cmake_build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/poco-1.10.1 && \
    make -j6 && make install && cp ../cmake/FindMySQL.cmake  /usr/local/share/cmake-3.14/Modules && \
    cd /tmp && rm Poco1.10.1 -r

#install spdlog-1.x
RUN cd /tmp && \
    git clone http://wanghualin:12345678@192.168.2.100:8888/KLAI/spdlog-1.x.git && \
    cd spdlog-1.x && mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/spdlog-1.4.0 -DBUILD_SHARED_LIBS=ON -DSPDLOG_BUILD_EXAMPLE=OFF -DSPDLOG_BUILD_TESTS=OFF && \
    make -j6 && make install && cd /tmp && rm spdlog-1.x -r

#install opencv
RUN cd /tmp && \
    git clone http://wanghualin:12345678@192.168.2.100:8888/KLAI/opencv4.3.git && \
    cd opencv4.3 && mkdir build && cd build && \
    export PKG_CONFIG_PATH=/usr/local/ffmpeg-4.3/lib/pkgconfig && \
    cp -d /usr/local/ffmpeg-4.3/lib/libswresample* /usr/lib/x86_64-linux-gnu && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/opencv-4.3.0  \
                                    -DWITH_CUDA=ON -DWITH_NVCUVID=ON -DBUILD_TESTS=OFF \
                                    -DBUILD_PERF_TESTS=OFF -DBUILD_EXAMPLES=OFF \
                                    -DOPENCV_EXTRA_MODULES_PATH=/tmp/opencv4.3/opencv_contrib-4.3.0/modules && \
    make -j6 && make install && rm /usr/lib/x86_64-linux-gnu/libswresample* && \
    cd /tmp && rm opencv4.3 -r

#install other tar.gz files
# COPY *.tar.gz /usr/local/
# RUN cd /usr/local &&  for file in ls *.tar.gz ;do tar -xvf $file ;done && rm *.tar.gz

#add LD_LIBRARY_PATH
RUN cd /etc/ld.so.conf.d && \
    echo "/usr/local/cpprest-sdk/lib" >> osmagic.conf && \
    echo "/usr/local/ffmpeg-4.3/lib" >> osmagic.conf && \
    echo "/usr/local/fmt/lib" >> osmagic.conf && \
    echo "/usr/local/jsoncpp-1.9.4/lib" >> osmagic.conf && \
    echo "/usr/local/opencv-4.3.0/lib" >> osmagic.conf && \
    echo "/usr/local/poco-1.10.1/lib" >> osmagic.conf && \
    echo "/usr/local/spdlog-1.4.0/lib/spdlog" >> osmagic.conf

#export pkg_config_path
ENV PKG_CONFIG_PATH=/usr/local/ffmpeg-4.3/lib/pkgconfig:/usr/local/fmt/lib/pkgconfig:/usr/local/jsoncpp-1.9.4/lib/pkgconfig

#export ffmpeg java path
ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/ffmpeg-4.3/bin

#export cmake module path
ENV CMAKE_MODULE_PATH=/usr/local/cpprest-sdk/lib/cpprestsdk:/usr/local/fmt/lib/cmake/fmt:/usr/local/jsoncpp-1.9.4/lib/cmake/jsoncpp:/usr/local/opencv-4.3.0/lib/cmake/opencv4:/usr/local/poco-1.10.1/lib/cmake/Poco:/usr/local/spdlog-1.4.0/lib/spdlog/cmake

#map nvidia driver so
ENV NVIDIA_DRIVER_CAPABILITIES=video,compute,utility

USER $USERNAME
WORKDIR /home/$USERNAME
