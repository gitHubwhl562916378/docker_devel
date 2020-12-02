# c++&algorithm开发环境搭建
======================================

使用Dockerfile构建开发环境

# 使用方法

>* 到release里面下载需要的cuda_10.2.1_linux.run(cuda10.2 blas的补丁包)到docker_devel目录
>* 将你开发需要的Video_Codec_SDK的头文件放到include, lib下面放Video_Codec_SDK要求的显卡驱动版本的  
   libnvcuvid.so.*.*文件与libnvidia-encode.so.*.*文件。 目前这个是video-sdk 8的，显卡驱动为440.82的编解码部分  
   如果没长升级video-sdk的需要，显卡驱动不一样时，换so到lib就可以了
>* `git clone http://192.168.2.100:8888/new_osmagic/cpp/docker_devel.git`
>* `cd docker_devel`
>* `docker build -t test:1.0 .`

# NOTE

>* 编译期间可能会因为网络问题，部分安装包失败，需要多尝试；或者可以将安装包先安装到基础镜像，Dockerfile中去掉该包再安装
>* 适用于10系列或20系列的镜像制作。如果是更高系列的卡，需要将FFmpeg下configure中的computre, code_sm算力都调整为35;  
   opencv cmake编译参数去掉CUDA部分，3.4.5的版本没入加入cuda11的配置，自己加比较麻烦