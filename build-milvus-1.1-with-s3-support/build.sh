#!/bin/sh


set -e

milvus_git_url=https://github.com/milvus-io/milvus.git
milvus_brach_ref=1.1
build_with_gpu=0


## modify below carefully

this_dir="$(cd $(dirname $0); pwd)"
builder_image=milvusdb/milvus-cpu-build-env:v0.7.0-centos7
gpu_build_args=""
build_hardware="cpu"
if [ $build_with_gpu -eq 1 ] ; then
    gpu_build_args="-g"
    build_hardware="gpu"
    builder_image=milvusdb/milvus-gpu-build-env:v0.7.0-centos7
fi

cd $this_dir

if [ -d milvus ] ; then
    echo milvus already cloned
else
    git clone --depth 5 -b $milvus_brach_ref $milvus_git_url milvus
fi

short_hash="$(cd milvus; git log -1  --format=format:%h)"

docker run --rm -ti -v $(pwd)/milvus:/milvus -e http_proxy=$http_proxy -e https_proxy=$https_proxy $builder_image bash -c "
  source scl_source enable devtoolset-7
  cd /milvus/core
  sh build.sh -t Release -s ${gpu_build_args}

"

cd milvus/docker/deploy/${build_hardware}/centos7
rm -fr milvus
cp -fr ../../../../core/milvus .

docker build --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy -t matrixji/milvus:${build_hardware}-s3-${short_hash} .

echo check image: matrixji/milvus:${build_hardware}-s3-${short_hash} .


